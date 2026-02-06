# Architecture Decision Records (ADRs)

This directory contains Architecture Decision Records for Project Chimera.

## What is an ADR?

An Architecture Decision Record (ADR) captures an important architectural decision made along with its context and consequences.

## ADR Index

| ADR | Title | Status | Date |
|-----|-------|--------|------|
| [ADR-001](001-database-choice.md) | PostgreSQL as Primary Database | Accepted | 2026-02-06 |
| [ADR-002](002-mcp-architecture.md) | Model Context Protocol for External I/O | Accepted | 2026-02-06 |
| [ADR-003](003-fastrender-swarm.md) | FastRender Swarm Pattern for Agent Coordination | Accepted | 2026-02-06 |
| [ADR-004](004-spec-driven-development.md) | Spec-Driven Development Workflow | Accepted | 2026-02-06 |
| [ADR-005](005-security-posture.md) | Security Architecture and Secrets Management | Accepted | 2026-02-06 |
| [ADR-006](006-multi-tenancy.md) | Multi-Tenancy Data Isolation Strategy | Accepted | 2026-02-06 |
| [ADR-007](007-hitl-governance.md) | Human-in-the-Loop Confidence-Based Routing | Accepted | 2026-02-06 |

## ADR Lifecycle

- **Proposed**: Under discussion
- **Accepted**: Decision made and implemented
- **Deprecated**: No longer recommended
- **Superseded**: Replaced by another ADR

## Creating a New ADR

1. Copy the template: `cp template.md XXX-title.md`
2. Fill in the sections
3. Submit for review
4. Update this index

## ADR Template

See [template.md](template.md) for the ADR template.
