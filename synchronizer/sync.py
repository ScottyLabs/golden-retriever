from __future__ import annotations

import json
import os
from pathlib import Path
from typing import Dict, Iterable, List, Set

from slack_sdk import WebClient
from slack_sdk.errors import SlackApiError

REPO_ROOT = Path(__file__).resolve().parents[1]
CONTRIBUTORS_DIR = REPO_ROOT / "contributors"
TEAMS_DIR = REPO_ROOT / "teams"


def _load_json_dir(path: Path) -> Dict[str, dict]:
    items: Dict[str, dict] = {}
    if not path.exists():
        return items
    for p in sorted(path.glob("*.json")):
        items[p.stem] = json.loads(p.read_text())
    return items


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


def main() -> None:
    token = os.getenv("SLACK_TOKEN", "").strip()
    if not token:
        print("SLACK_TOKEN missing; skipping Slack sync")
        return

    contributors = _load_json_dir(CONTRIBUTORS_DIR)
    teams = _load_json_dir(TEAMS_DIR)

    client = WebClient(token=token)
    channels = _channel_lookup(client)

    for team_slug, team in teams.items():
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


if __name__ == "__main__":
    main()
