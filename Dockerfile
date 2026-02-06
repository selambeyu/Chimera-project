# Project Chimera - encapsulated environment for tests and CI
# Python 3.12; installs deps and runs tests

FROM python:3.12-slim

WORKDIR /app

COPY pyproject.toml ./
COPY skills/ skills/
COPY tests/ tests/
COPY specs/ specs/

# Install test deps (no application package required by challenge)
RUN pip install --no-cache-dir pytest pytest-asyncio

ENV PYTHONPATH=/app
ENV PYTHONDONTWRITEBYTECODE=1

# Default: run tests
CMD ["python", "-m", "pytest", "tests/", "-v", "--tb=short"]
