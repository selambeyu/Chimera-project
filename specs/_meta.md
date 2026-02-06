# Project Chimera: Master Specification (Meta)

**Document**: High-level vision and constraints  
**Role**: Source of truth for the Autonomous Influencer Network  
**Last updated**: 2025-02-04

---

## Vision

Project Chimera is an **Autonomous Influencer Network** (AiQEM). It transitions from automated content scheduling to **Autonomous Influencer Agents**—persistent, goal-directed digital entities with perception, reasoning, creative expression, and economic agency. The system supports a scalable fleet of agents (potentially thousands) managed by a single Orchestrator, operating with significant individual autonomy.

**Strategic pillars**:
- **MCP (Model Context Protocol)** for universal connectivity to the external world (social, news, memory, commerce).
- **FastRender Swarm** (Planner / Worker / Judge) for internal task coordination and parallel execution.
- **Agentic Commerce** (e.g. Coinbase AgentKit) for non-custodial wallets and on-chain transactions.

---

## Constraints

1. **Spec-first**: No implementation code is written until the relevant specification is ratified. All intent lives under `specs/`.
2. **MCP-only external I/O**: All external data and actions (social, news, DB, wallet) go through MCP Resources and Tools. No direct API calls from agent core logic.
3. **Human-in-the-Loop**: Content and high-risk actions are subject to confidence-based routing; low confidence or sensitive topics require human review before commit.
4. **Single-orchestrator model**: One human Super-Orchestrator manages AI Manager Agents, who direct Worker Swarms. Governance and brand rules are centralized (e.g. AGENTS.md / BoardKit-style config).
5. **Multi-tenancy**: Strict data isolation between tenants; agent memories and financial assets are never shared across tenants.
6. **Transparency**: Agents must support self-disclosure (e.g. platform AI labels, honesty directive when asked “Are you AI?”).

---

## Repository Blueprint

- **specs/_meta.md** (this file): Vision and constraints.
- **specs/functional.md**: User stories and acceptance criteria.
- **specs/technical.md**: API contracts, database schema, and technical interfaces.
- **specs/openclaw_integration.md**: Integration with the OpenClaw / Agent Social Network (optional).

All agents and developers MUST resolve intent from `specs/` before writing or changing code.
