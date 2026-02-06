# Project Chimera - standardised commands (Task 3.2)
# make setup | make test | make spec-check | make lint | make security | make governance

.PHONY: setup test spec-check lint security governance test-docker

# Install dependencies (local)
setup:
	pip install -e ".[dev]"
	@echo "Run 'make test' to run tests."

# Run tests (failing tests define the TDD slot until implementation)
test:
	python -m pytest tests/ -v --tb=short

# Run tests inside Docker (CI-style)
test-docker:
	docker build -t chimera-test .
	docker run --rm chimera-test

# Optional: verify code aligns with specs (presence of spec files and key contracts)
spec-check:
	@echo "=== Spec alignment check ==="
	@test -f specs/_meta.md && echo "  OK specs/_meta.md" || (echo "  MISSING specs/_meta.md"; exit 1)
	@test -f specs/functional.md && echo "  OK specs/functional.md" || (echo "  MISSING specs/functional.md"; exit 1)
	@test -f specs/technical.md && echo "  OK specs/technical.md" || (echo "  MISSING specs/technical.md"; exit 1)
	@grep -q "Trend Data" specs/technical.md && echo "  OK Trend Data contract in technical.md" || (echo "  MISSING Trend Data in technical.md"; exit 1)
	@echo "  Spec check passed."

# Lint (ruff): skills/ and tests/
lint:
	ruff check skills/ tests/

# Security (bandit): skills/ only (tests may use assert)
security:
	bandit -r skills/ -c pyproject.toml

# Governance pipeline: lint + security + tests (run automatically in CI and Docker)
governance: spec-check lint security test
	@echo "=== Governance passed ==="
