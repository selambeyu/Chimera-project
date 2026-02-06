# Tooling & Skills Strategy

**Document**: Developer tools (MCP) and agent skills strategy
**Task**: 2.3 Tooling & Skills Strategy
**Last updated**: 2025-02-04

---

## Sub-Task A: Developer Tools (MCP)

MCP servers used **by developers** to build and operate the Chimera repo (not necessarily at agent runtime).

### Selected MCP Servers

| MCP Server | Purpose | Configuration |
|------------|---------|---------------|
| **Tenx MCP Sense** (Chimera-project-tenxfeedbackanalytics) | Telemetry and “Black Box” flight recorder; traceability for assessment. | Connect in Cursor Settings → MCP; authenticate with 10 Academy / Tenx. Must stay connected during development. |
| **GitHub MCP** (project-0-_Chimera-project-github) | Version control from the IDE: list issues, create PRs, search code, manage branches. | Used for Git hygiene (commit often, branch per feature) and spec-linked PRs. |
| **Cursor IDE Browser** | Frontend and web testing; navigate and interact with pages for Dashboard or HITL UI. | Use for testing Review UI or Orchestrator Dashboard in browser. |

### Optional / Future

- **filesystem MCP** (or native Cursor file tools): Navigate and edit files; align with `specs/` when creating or updating modules.
- **Database MCP** (e.g. PostgreSQL): Inspect schema, run read-only queries during development; not for production agent runtime (agents use MCP or Skills with defined contracts).

### Principle

Developer MCPs are for **humans and IDE agents** to develop, review, and debug. Runtime agent capabilities are defined by **Skills** (see below) and **MCP servers that the Chimera agents call** (e.g. social, news, wallet), which are documented in `specs/technical.md` and in the SRS.

---

## Sub-Task B: Agent Skills (Runtime)

**Definition**: A **Skill** is a specific capability package the Chimera Agent uses at runtime (e.g. `skill_download_youtube`, `skill_transcribe_audio`). Skills have clear Input/Output contracts and live under `skills/`. They may wrap MCP tools or custom logic; the important part is the stable interface.

### Skills Directory Layout

```
skills/
├── README.md           # Overview and index of skills
├── skill_fetch_trends/ # Trend data for Planner
├── skill_transcribe_audio/
└── skill_download_youtube/
```

Each skill has a README defining:
- Purpose
- Input contract (parameters, types)
- Output contract (structure matching specs/technical.md where applicable)
- Dependencies (MCP server, env vars)
- No full implementation required yet; structure and contracts only.

See `skills/README.md` and each `skills/skill_*/README.md` for the three critical skills and their I/O contracts.
