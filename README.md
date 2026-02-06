# Project Chimera

**Autonomous Influencer Network** (AiQEM)—persistent, goal-directed digital entities that research trends, generate content, and manage engagement. This repository is the **spec-driven “factory”** for building that system: intent lives in `specs/`, agent capabilities in `skills/`, and TDD tests define the slots to implement.

Built for the **Project Chimera 3-Day Challenge** (FDE Trainee): Spec-Driven Development, MCP tooling, and governance (Docker, Makefile, CI).

---

## Principles

- **Spec-first**: No implementation without a ratified spec. See [specs/_meta.md](specs/_meta.md).
- **Single source of truth**: [specs/functional.md](specs/functional.md) (user stories), [specs/technical.md](specs/technical.md) (API contracts, DB schema), [specs/openclaw_integration.md](specs/openclaw_integration.md) (OpenClaw).
- **Skills vs MCP**: [skills/](skills/README.md) are runtime capabilities (e.g. fetch trends, transcribe, download); MCP servers are external bridges (see [research/tooling_strategy.md](research/tooling_strategy.md)).

---

## Repository layout

| Path | Purpose |
|------|---------|
| **specs/** | Vision, constraints, user stories, API/DB contracts |
| **skills/** | Agent skills: `skill_fetch_trends`, `skill_transcribe_audio`, `skill_download_youtube` (I/O in READMEs + technical.md) |
| **tests/** | TDD: `test_trend_fetcher.py`, `test_skills_interface.py` (failing until skills are implemented) |
| **research/** | Tooling strategy (dev MCPs, skills) |
| **.cursor/rules/** | Project context, Prime Directive, traceability |
| **.github/workflows/** | CI: run tests on push |

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
| `make lint` | Run ruff on `skills/` and `tests/` (requires ruff) |
| `make security` | Run bandit on `skills/` (requires bandit) |
| `make governance` | spec-check + lint + security + test |

---

## Tenx MCP Sense & connection log

- Connect **Tenx MCP Sense** in Cursor (Settings → MCP → Chimera-project-tenxfeedbackanalytics). See [docs/setup/tenx-mcp-sense.md](docs/setup/tenx-mcp-sense.md).
- Record the confirmed connection in [CONNECTION_LOG.md](CONNECTION_LOG.md).

---

## CI/CD

- **GitHub Actions** ( [.github/workflows/main.yml](.github/workflows/main.yml) ): on push/PR, runs `make test` and `make test-docker`.
- **CodeRabbit** ( [.coderabbit.yaml](.coderabbit.yaml) ): review instructions for spec alignment and security.

---

## References

- [Project Chimera SRS](docs/setup/Project%20Chimera%20SRS%20Document_%20Autonomous%20Influencer%20Network.pdf) — full system spec.
- [3-Day Challenge](docs/setup/Project_Chimera_3Day_Challenge.md.pdf) — FDE roadmap (Tasks 1–3).
- [CLAUDE.md](CLAUDE.md) — AI assistant context for this repo.
