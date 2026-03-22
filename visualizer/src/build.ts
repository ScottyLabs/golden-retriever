import { readFileSync, readdirSync, writeFileSync, mkdirSync, existsSync } from "fs";
import { join, basename } from "path";

const ROOT = join(import.meta.dirname!, "..");
const WORKSPACE = join(ROOT, "..");

interface Contributor {
  full_name: string;
  github_username?: string;
  forgejo_username?: string;
}

interface Repository {
  name: string;
  slug: string;
  description?: string;
  github?: string;
  forgejo?: string;
}

interface FigmaProject {
  name: string;
  slug: string;
  url?: string;
}

interface GoogleFile {
  name: string;
  slug: string;
  url: string;
}

interface Team {
  name: string;
  slug: string;
  description?: string;
  maintainers: string[];
  contributors: string[];
  repos?: string[];
  figma_projects?: string[];
  google_files?: string[];
}

interface GraphNode {
  id: string;
  name: string;
  nodeType: "Contributor" | "Team" | "Repo" | "Figma" | "GFile";
  url?: string;
}

interface GraphLink {
  source: string;
  target: string;
  linkType: string;
}

interface GraphData {
  nodes: GraphNode[];
  links: GraphLink[];
}

function loadJsonDir<T>(dir: string): Map<string, T> {
  const fullDir = join(WORKSPACE, dir);
  if (!existsSync(fullDir)) return new Map();
  const map = new Map<string, T>();
  for (const file of readdirSync(fullDir)) {
    if (!file.endsWith(".json")) continue;
    const slug = basename(file, ".json");
    const data = JSON.parse(readFileSync(join(fullDir, file), "utf-8"));
    map.set(slug, data);
  }
  return map;
}

function buildGraph(
  contributors: Map<string, Contributor>,
  teams: Map<string, Team>,
  repos: Map<string, Repository>,
  figmaProjects: Map<string, FigmaProject>,
  googleFiles: Map<string, GoogleFile>,
): Record<string, GraphData> {
  const allNodes: GraphNode[] = [];
  const allLinks: GraphLink[] = [];

  for (const [slug, c] of contributors) {
    allNodes.push({
      id: `contributor:${slug}`,
      name: c.full_name,
      nodeType: "Contributor",
      url: c.github_username
        ? `https://github.com/${c.github_username}`
        : undefined,
    });
  }

  for (const [slug, r] of repos) {
    allNodes.push({
      id: `repo:${slug}`,
      name: r.name,
      nodeType: "Repo",
      url: r.github
        ? `https://github.com/${r.github}`
        : r.forgejo
          ? `https://codeberg.org/${r.forgejo}`
          : undefined,
    });
  }

  for (const [slug, fp] of figmaProjects) {
    allNodes.push({
      id: `figma:${slug}`,
      name: fp.name,
      nodeType: "Figma",
      url: fp.url,
    });
  }

  for (const [slug, gf] of googleFiles) {
    allNodes.push({
      id: `gfile:${slug}`,
      name: gf.name,
      nodeType: "GFile",
      url: gf.url,
    });
  }

  for (const [slug, t] of teams) {
    allNodes.push({
      id: `team:${slug}`,
      name: t.name,
      nodeType: "Team",
    });

    const maintainerSet = new Set(t.maintainers);

    for (const c of t.contributors) {
      allLinks.push({
        source: `team:${slug}`,
        target: `contributor:${c}`,
        linkType: maintainerSet.has(c) ? "maintainer" : "member",
      });
    }

    for (const r of t.repos ?? []) {
      allLinks.push({
        source: `team:${slug}`,
        target: `repo:${r}`,
        linkType: "team-repo",
      });
    }

    for (const fp of t.figma_projects ?? []) {
      allLinks.push({
        source: `team:${slug}`,
        target: `figma:${fp}`,
        linkType: "team-figma",
      });
    }

    for (const gf of t.google_files ?? []) {
      allLinks.push({
        source: `team:${slug}`,
        target: `gfile:${gf}`,
        linkType: "team-gfile",
      });
    }
  }

  const contributorOnlyNodes = allNodes.filter(
    (n) => n.nodeType === "Contributor" || n.nodeType === "Team",
  );
  const contributorOnlyLinks = allLinks.filter(
    (l) => l.linkType === "maintainer" || l.linkType === "member",
  );

  return {
    default: { nodes: allNodes, links: allLinks },
    people: { nodes: contributorOnlyNodes, links: contributorOnlyLinks },
  };
}

function generateHtml(datasets: Record<string, GraphData>): string {
  const template = readFileSync(
    join(ROOT, "templates", "index.html"),
    "utf-8",
  );
  return template.replace("__GRAPH_DATA__", JSON.stringify(datasets));
}

const contributors = loadJsonDir<Contributor>("contributors");
const teams = loadJsonDir<Team>("teams");
const repos = loadJsonDir<Repository>("repos");
const figmaProjects = loadJsonDir<FigmaProject>("figma-projects");
const googleFiles = loadJsonDir<GoogleFile>("google-files");

const datasets = buildGraph(contributors, teams, repos, figmaProjects, googleFiles);
const html = generateHtml(datasets);

const distDir = join(WORKSPACE, "dist");
mkdirSync(distDir, { recursive: true });
writeFileSync(join(distDir, "index.html"), html);
console.log(`Wrote ${join(distDir, "index.html")}`);
