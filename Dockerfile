# Project Chimera - encapsulated environment for governance (lint, security, tests)
# Python 3.12; used by CI for reproducible lint + security + test runs

FROM python:3.12-slim

WORKDIR /app

COPY pyproject.toml ./
COPY skills/ skills/
COPY tests/ tests/
COPY specs/ specs/

# Install dev deps: tests + lint + security
RUN pip install --no-cache-dir pytest pytest-asyncio ruff "bandit[toml]"

ENV PYTHONPATH=/app
ENV PYTHONDONTWRITEBYTECODE=1

# Governance: lint → security → tests (run automatically in CI)
CMD ["sh", "-c", "ruff check skills/ tests/ && bandit -r skills/ -c pyproject.toml && python -m pytest tests/ -v --tb=short"]
