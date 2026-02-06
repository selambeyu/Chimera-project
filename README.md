# Project Chimera

**Autonomous Influencer Network** (AiQEM)—persistent, goal-directed digital entities that research trends, generate content, and manage engagement. This repository is the **spec-driven "factory"** for building that system: intent lives in `specs/`, agent capabilities in `skills/`, and TDD tests define the slots to implement.

Built for the **Project Chimera 3-Day Challenge** (FDE Trainee): Spec-Driven Development, MCP tooling, and governance (Docker, Makefile, CI).

---

## Principles

- **Spec-first**: No implementation without a ratified spec. See [specs/_meta.md](specs/_meta.md) and [ADR-004](docs/adr/004-spec-driven-development.md).
- **Single source of truth**: [specs/functional.md](specs/functional.md) (user stories), [specs/technical.md](specs/technical.md) (API contracts, DB schema), [specs/api_endpoints.md](specs/api_endpoints.md) (REST API).
- **Skills vs MCP**: [skills/](skills/README.md) are runtime capabilities; MCP servers are external bridges (see [specs/mcp_servers.md](specs/mcp_servers.md)).
- **Security**: See [SECURITY.md](SECURITY.md) and [ADR-005](docs/adr/005-security-posture.md).

---

## Repository layout

| Path | Purpose |
|------|---------|
| **specs/** | Vision, constraints, user stories, API/DB contracts, acceptance criteria |
| **skills/** | Agent skills: `skill_fetch_trends`, `skill_transcribe_audio`, `skill_download_youtube` |
| **tests/** | TDD: `test_trend_fetcher.py`, `test_skills_interface.py` (failing until implemented) |
| **docs/adr/** | Architecture Decision Records (DB choice, MCP, security, SDD) |
| **.cursor/rules/** | Project context, Prime Directive, traceability, MCP governance |
| **.github/workflows/** | CI: lint, security, tests |

---

## Quick setup

- **Python 3.12** (see [.python-version](.python-version)).
- **Install deps** (from repo root):
  ```bash
  make setup
  ```
  Or with [uv](https://github.com/astral-sh/uv): `uv sync` then `uv run pytest tests/ -v`.
- **Run tests** (expected to fail until skills are implemented):
  ```bash
  make test
  ```

Optional: [docs/setup/golden-environment.md](docs/setup/golden-environment.md) for full env (PostgreSQL, Redis, uv).

---

## Commands

| Command | Description |
|--------|-------------|
| `make setup` | Install dependencies (`pip install -e ".[dev]"`) |
| `make test` | Run pytest (TDD tests) |
| `make test-docker` | Build image and run tests in Docker |
| `make spec-check` | Verify spec files and key contracts (e.g. Trend Data) |
| `make lint` | Run ruff on `skills/` and `tests/` |
| `make security` | Run bandit on `skills/` |
| `make governance` | spec-check + lint + security + test |

---

## Documentation

### Specifications

- [specs/_meta.md](specs/_meta.md) - Vision, constraints, principles
- [specs/functional.md](specs/functional.md) - User stories (OP-1, OP-2, REV-1, A-1 to A-5)
- [specs/technical.md](specs/technical.md) - API contracts, database schema (ERD)
- [specs/api_endpoints.md](specs/api_endpoints.md) - REST API specification (explicit endpoints, JSON schemas)
- [specs/acceptance_criteria.md](specs/acceptance_criteria.md) - Given/When/Then scenarios for all features
- [specs/mcp_servers.md](specs/mcp_servers.md) - MCP server definitions (tools, resources, auth)
- [specs/openclaw_protocol.md](specs/openclaw_protocol.md) - OpenClaw integration protocol
- [specs/rule_intent.md](specs/rule_intent.md) - Rule categories, forbidden actions, escalation

### Architecture Decision Records (ADRs)

- [ADR-001: PostgreSQL as Primary Database](docs/adr/001-database-choice.md)
- [ADR-002: Model Context Protocol for External I/O](docs/adr/002-mcp-architecture.md)
- [ADR-004: Spec-Driven Development Workflow](docs/adr/004-spec-driven-development.md)
- [ADR-005: Security Architecture and Secrets Management](docs/adr/005-security-posture.md)

See [docs/adr/README.md](docs/adr/README.md) for complete index.

### Security

- [SECURITY.md](SECURITY.md) - Security policy, vulnerability reporting, best practices

---

## Tenx MCP Sense & connection log

- Connect **Tenx MCP Sense** in Cursor (Settings → MCP → Chimera-project-tenxfeedbackanalytics). See [docs/setup/tenx-mcp-sense.md](docs/setup/tenx-mcp-sense.md).
- Record the confirmed connection in [CONNECTION_LOG.md](CONNECTION_LOG.md).

---

## CI/CD

- **GitHub Actions** ([.github/workflows/main.yml](.github/workflows/main.yml)): on push/PR, runs `make governance` (lint, security, tests)
- **CodeRabbit** ([.coderabbit.yaml](.coderabbit.yaml)): AI review for spec alignment and security

---

## References

- [Project Chimera SRS](docs/Project%20Chimera%20SRS%20Document_%20Autonomous%20Influencer%20Network.pdf) — Full system specification
- [3-Day Challenge](docs/Project_Chimera_3Day_Challenge.md.pdf) — FDE roadmap (Tasks 1–3)
- [Golden Environment Setup](docs/setup/golden-environment.md) — Python + PostgreSQL setup
- [Tenx MCP Sense Setup](docs/setup/tenx-mcp-sense.md) — IDE telemetry connection
