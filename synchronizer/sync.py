from __future__ import annotations

import json
import os
import time
import urllib.error
import urllib.request
from pathlib import Path
from typing import Callable, Dict, Iterable, List, Set

from slack_sdk import WebClient
from slack_sdk.errors import SlackApiError

REPO_ROOT = Path(__file__).resolve().parents[1]
CONTRIBUTORS_DIR = REPO_ROOT / "contributors"
TEAMS_DIR = REPO_ROOT / "teams"

DISCORD_API = "https://discord.com/api/v10"
UA = "GoldenRetrieverGovernanceSync (https://github.com/ScottyLabs/golden-retriever, 0.1)"
DISCORD_MESSAGE_MAX = 2000


def _load_json_dir(path: Path) -> Dict[str, dict]:
    items: Dict[str, dict] = {}
    if not path.exists():
        return items
    for p in sorted(path.glob("*.json")):
        items[p.stem] = json.loads(p.read_text())
    return items


def _team_flag(team: dict, key: str, *, default: bool) -> bool:
    """JSON omits keys; treat missing like schema default."""
    if key not in team:
        return default
    return bool(team[key])


def _channel_lookup(client: WebClient) -> Dict[str, str]:
    lookup: Dict[str, str] = {}
    cursor = None
    while True:
        resp = client.conversations_list(
            types="public_channel,private_channel",
            exclude_archived=True,
            limit=1000,
            cursor=cursor,
        )
        for ch in resp.get("channels", []):
            cid = ch.get("id")
            name = ch.get("name")
            if not cid:
                continue
            lookup[cid] = cid
            if name:
                lookup[name] = cid
                lookup[f"#{name}"] = cid
        cursor = resp.get("response_metadata", {}).get("next_cursor")
        if not cursor:
            break
    return lookup


def _chunk(xs: List[str], n: int) -> Iterable[List[str]]:
    for i in range(0, len(xs), n):
        yield xs[i : i + n]


def _safe_join_public(client: WebClient, channel_id: str) -> None:
    try:
        client.conversations_join(channel=channel_id)
    except SlackApiError as e:
        err = e.response.get("error", "unknown_error")
        if err in {"method_not_supported_for_channel_type", "already_in_channel", "is_private"}:
            return
        raise


def _invite_users(client: WebClient, channel_id: str, user_ids: List[str]) -> None:
    if not user_ids:
        return
    _safe_join_public(client, channel_id)
    for batch in _chunk(user_ids, 30):
        try:
            client.conversations_invite(channel=channel_id, users=",".join(batch))
        except SlackApiError as e:
            err = e.response.get("error", "unknown_error")
            if err in {"already_in_channel", "already_invited", "cant_invite_self", "missing_scope"}:
                continue
            if err == "not_in_channel":
                print(f"WARN: bot is not in private channel {channel_id}; invite the app there first")
                continue
            if err == "user_not_found":
                print(f"WARN: user not found while inviting to {channel_id}")
                continue
            raise


def _sync_slack(contributors: Dict[str, dict], teams: Dict[str, dict], token: str) -> None:
    client = WebClient(token=token)
    channels = _channel_lookup(client)

    for team_slug, team in teams.items():
        if not _team_flag(team, "sync_slack", default=True):
            continue
        member_slugs: Set[str] = set(team.get("contributors", [])) | set(team.get("maintainers", []))
        user_ids = [
            contributors[s].get("slack_user_id", "").strip()
            for s in sorted(member_slugs)
            if s in contributors and contributors[s].get("slack_user_id")
        ]
        user_ids = sorted({u for u in user_ids if u})

        for chan in team.get("slack_channels", []) or []:
            raw = str(chan).strip()
            if not raw:
                continue
            channel_id = channels.get(raw)
            if not channel_id:
                print(f"WARN: teams/{team_slug}.json references unknown Slack channel {raw!r}")
                continue
            _invite_users(client, channel_id, user_ids)
            print(f"OK: invited {len(user_ids)} users from team {team_slug} to {raw} ({channel_id})")


def _discord_add_role(bot_token: str, guild_id: str, user_id: str, role_id: str, *, retry: bool = True) -> str | None:
    """Returns None on success, or a short error label for logging."""
    url = f"{DISCORD_API}/guilds/{guild_id}/members/{user_id}/roles/{role_id}"
    req = urllib.request.Request(url, method="PUT", data=b"")
    req.add_header("Authorization", f"Bot {bot_token}")
    req.add_header("User-Agent", UA)
    try:
        with urllib.request.urlopen(req, timeout=30) as resp:
            if resp.status in (200, 204):
                return None
            return f"unexpected_status_{resp.status}"
    except urllib.error.HTTPError as e:
        if e.code == 429 and retry:
            wait = float(e.headers.get("Retry-After", "1"))
            time.sleep(wait)
            return _discord_add_role(bot_token, guild_id, user_id, role_id, retry=False)
        if e.code in (200, 204):
            return None
        if e.code == 404:
            return "unknown_member"
        if e.code == 403:
            return "missing_permissions"
        if e.code == 400:
            return "bad_request"
        return f"http_{e.code}"
    except urllib.error.URLError as e:
        return f"network_{e.reason!s}"


def _discord_post_channel_message(
    bot_token: str, channel_id: str, content: str, *, retry: bool = True
) -> str | None:
    """Post a message to a text channel. Returns None on success, or a short error label."""
    text = content.strip()
    if len(text) > DISCORD_MESSAGE_MAX:
        text = text[: DISCORD_MESSAGE_MAX - 1] + "…"
    url = f"{DISCORD_API}/channels/{channel_id}/messages"
    payload = json.dumps({"content": text}).encode("utf-8")
    req = urllib.request.Request(url, method="POST", data=payload)
    req.add_header("Authorization", f"Bot {bot_token}")
    req.add_header("Content-Type", "application/json")
    req.add_header("User-Agent", UA)
    try:
        with urllib.request.urlopen(req, timeout=30) as resp:
            if resp.status in (200, 201):
                return None
            return f"unexpected_status_{resp.status}"
    except urllib.error.HTTPError as e:
        if e.code == 429 and retry:
            wait = float(e.headers.get("Retry-After", "1"))
            time.sleep(wait)
            return _discord_post_channel_message(bot_token, channel_id, content, retry=False)
        if e.code in (200, 201):
            return None
        if e.code == 403:
            return "missing_access"
        if e.code == 404:
            return "unknown_channel"
        return f"http_{e.code}"
    except urllib.error.URLError as e:
        return f"network_{e.reason!s}"


def _sync_discord(
    contributors: Dict[str, dict],
    teams: Dict[str, dict],
    bot_token: str,
    guild_id: str,
    discord_log: Callable[[str], None],
) -> None:
    for team_slug, team in teams.items():
        if not _team_flag(team, "sync_discord_roles", default=True):
            continue
        dr = team.get("discord_roles")
        if not dr or not isinstance(dr, dict):
            continue
        maint_r = str(dr.get("maintainer") or "").strip()
        contrib_r = str(dr.get("contributor") or "").strip()
        if not maint_r and not contrib_r:
            continue

        def discord_uid(slug: str) -> str:
            c = contributors.get(slug) or {}
            return str(c.get("discord_id") or "").strip()

        maint_slugs = set(team.get("maintainers", []))
        contrib_slugs = set(team.get("contributors", []))

        pairs: List[tuple[str, str, str]] = []
        if maint_r:
            for s in sorted(maint_slugs):
                uid = discord_uid(s)
                if uid:
                    pairs.append((s, uid, maint_r))
        if contrib_r:
            for s in sorted(contrib_slugs):
                uid = discord_uid(s)
                if uid:
                    pairs.append((s, uid, contrib_r))

        seen: Set[tuple[str, str]] = set()
        for slug, uid, rid in pairs:
            key = (uid, rid)
            if key in seen:
                continue
            seen.add(key)
            err = _discord_add_role(bot_token, guild_id, uid, rid)
            if err == "unknown_member":
                msg = (
                    f"WARN: Discord user {uid} ({slug}) is not in guild {guild_id}; "
                    f"they must join the server before roles can be assigned"
                )
                print(msg)
                discord_log(f"**Governance sync** — role assign failed (unknown member)\n```{msg}```")
            elif err == "missing_permissions":
                msg = (
                    f"WARN: bot lacks permission to add role {rid} for team {team_slug} "
                    f"(check Manage Roles and role hierarchy)"
                )
                print(msg)
                discord_log(f"**Governance sync** — role assign failed (permissions)\n```{msg}```")
            elif err:
                msg = f"WARN: Discord role add failed team={team_slug} user={uid} role={rid}: {err}"
                print(msg)
                discord_log(f"**Governance sync** — role assign failed\n```{msg}```")
            else:
                msg = f"Added Discord role for team ```{team_slug}``` on user ```{slug}```)"
                print(msg)
                discord_log(f"**Governance sync** — role assign succeeded\n```{msg}```")


def main() -> None:
    contributors = _load_json_dir(CONTRIBUTORS_DIR)
    teams = _load_json_dir(TEAMS_DIR)

    slack_token = os.getenv("SLACK_TOKEN", "").strip()
    if slack_token:
        _sync_slack(contributors, teams, slack_token)
    else:
        print("SLACK_TOKEN missing; skipping Slack sync")

    discord_token = os.getenv("DISCORD_BOT_TOKEN", "").strip()
    guild_id = os.getenv("DISCORD_GUILD_ID", "").strip()
    log_channel = os.getenv("DISCORD_LOG_CHANNEL_ID", "").strip()
    log_channel_post_warned = False

    def discord_log(message: str) -> None:
        nonlocal log_channel_post_warned
        if not (discord_token and log_channel):
            return
        err = _discord_post_channel_message(discord_token, log_channel, message)
        if err and not log_channel_post_warned:
            print(
                f"WARN: could not post to Discord log channel ({err}); "
                f"check DISCORD_LOG_CHANNEL_ID and bot View Channel / Send Messages"
            )
            log_channel_post_warned = True

    if discord_token and guild_id:
        _sync_discord(contributors, teams, discord_token, guild_id, discord_log)
    elif discord_token or guild_id:
        msg = "WARN: set both DISCORD_BOT_TOKEN and DISCORD_GUILD_ID for Discord sync; skipping Discord sync"
        print(msg)
        discord_log(f"**Governance sync** — Discord misconfiguration\n```{msg}```")
    else:
        print("DISCORD_BOT_TOKEN / DISCORD_GUILD_ID missing; skipping Discord sync")


if __name__ == "__main__":
    main()
