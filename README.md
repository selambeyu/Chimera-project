# Project Chimera

**Autonomous Influencer Network** (AiQEM)—persistent, goal-directed digital entities that research trends, generate content, and manage engagement. Built with **Spec-Driven Development**: intent and contracts live in `specs/`; MCP for external I/O; FastRender Swarm (Planner / Worker / Judge) for task coordination.

- **Spec-first**: No implementation without a ratified spec. See [specs/_meta.md](specs/_meta.md), [specs/functional.md](specs/functional.md), [specs/technical.md](specs/technical.md).
- **Skills**: Reusable agent capabilities under [skills/](skills/README.md) (e.g. `skill_fetch_trends`, `skill_transcribe_audio`, `skill_download_youtube`) with I/O aligned to `specs/technical.md`.
---

## Quick setup

Development uses a **golden environment** (see [docs/setup/golden-environment.md](docs/setup/golden-environment.md)).

1. **Install [uv](https://github.com/astral-sh/uv):** `curl -LsSf https://astral.sh/uv/install.sh | sh`
2. **Python 3.12** (uv uses `.python-version` or installs it).
3. **Sync dependencies** (creates `.venv` and lockfile):
   ```bash
   uv sync
   ```
---

## Development

| Command | Description |
|--------|-------------|
| `make setup` | Install deps (`pip install -e ".[dev]"`) |
| `make test` | Run pytest |
| `make spec-check` | Verify spec files and key contracts |
| `make lint` | Ruff on `skills/` and `tests/` |
| `make security` | Bandit on `skills/` |
| `make governance` | spec-check + lint + security + test (CI/Docker pipeline) |
| `make test-docker` | Build and run tests in Docker |

### Commit hooks (pre-commit)

Hooks run automatically before each commit (lint, trailing whitespace, YAML check, etc.).

1. Install dev deps (e.g. `uv sync` or `make setup`), then:
   ```bash
   pre-commit install
   ```
2. On each commit, staged files are checked. To run on all files: `pre-commit run --all-files`.
3. Config: [.pre-commit-config.yaml](.pre-commit-config.yaml).

---

## Repository layout

| Path | Purpose |
|------|---------|
| `specs/` | Vision, user stories, API/DB contracts—single source of truth |
| `skills/` | Agent runtime skills (trends, transcribe, download) |
| `tests/` | Unit tests; Trend Data and skill interfaces |
| `.cursor/rules/` | Agent rules (spec-first, traceability) |
