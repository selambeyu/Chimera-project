# Functional Specification: User Stories

**Document**: Executable intent for agents and operators  
**Source**: Project Chimera SRS  
**Last updated**: 2025-02-04

---

## User Personas

- **Network Operator**: Sets campaign goals, monitors fleet, does not write content.
- **Human Reviewer (HITL)**: Approves, rejects, or edits agent-generated content.
- **Chimera Agent**: Autonomous entity that perceives, plans, generates, and acts via MCP.
- **Developer / System Architect**: Extends MCP servers, personas, and infrastructure.

---

## User Stories (Operator & Reviewer)

### OP-1: Define campaign goals
- **As a** Network Operator, **I need to** submit a natural-language campaign goal (e.g. “Promote summer fashion in Ethiopia”) **so that** the system decomposes it into executable tasks.
- **Acceptance**: Goal is stored; Planner produces a visible task tree; operator can inspect or modify before execution.

### OP-2: Monitor fleet status
- **As a** Network Operator, **I need to** view fleet status (Planning / Working / Judging / Sleeping), queue depth, and wallet balance **so that** I can manage capacity and budget.
- **Acceptance**: Dashboard shows current state, HITL queue depth, and financial health per agent or aggregate.

### REV-1: Review escalated content
- **As a** Human Reviewer, **I need to** see a queue of items with content, confidence score, and reasoning **so that** I can Approve, Reject, or Edit before publish.
- **Acceptance**: Review UI shows each item; Approve commits and removes from queue; Reject discards or re-queues for retry.

---

## User Stories (Agent-as-Actor)

Stories below are written in “As an Agent” form for traceability to skills and MCP tools.

### A-1: Fetch trends
- **As an** Agent, **I need to** fetch trend data (e.g. news, social signals) via a defined interface **so that** the Planner can decide what content to create.
- **Acceptance**: Trend data structure matches the API contract in `specs/technical.md`; data is sourced via MCP Resources or Skills.

### A-2: Generate content
- **As an** Agent, **I need to** generate text, image, or video content using persona and memory **so that** it can be judged and optionally published.
- **Acceptance**: Content is produced via MCP Tools (e.g. image/video generators); Character Consistency Lock is applied for images.

### A-3: Publish and engage
- **As an** Agent, **I need to** post, reply, and like via MCP Tools (no direct platform APIs) **so that** all actions are governed and logged.
- **Acceptance**: All social actions go through MCP layer; rate limiting and dry-run are enforced.

### A-4: Manage memory
- **As an** Agent, **I need to** read and write short-term (Redis) and long-term (Weaviate) memory via a defined contract **so that** context is consistent across tasks.
- **Acceptance**: Memory read/write uses specified schemas and MCP or Skill interfaces.

### A-5: Execute commerce
- **As an** Agent, **I need to** check balance and execute on-chain actions (e.g. transfer USDC) within budget rules **so that** I can participate in agentic commerce safely.
- **Acceptance**: Balance check before cost-incurring workflows; CFO Judge enforces limits; keys from secrets manager.

---

## Edge Cases (Functional)

- **Empty or unavailable MCP**: Fallback or HITL; no silent failure.
- **Confidence below threshold**: Route to HITL; do not auto-publish.
- **Sensitive topic detected**: Always HITL regardless of confidence.
- **Budget exceeded**: CFO Judge rejects; task flagged for human review.
