# ADR-004: Spec-Driven Development Workflow

## Status

**Accepted** - 2026-02-06

## Context

Project Chimera is designed to be built by a **swarm of AI agents** with minimal human conflict. Traditional development workflows (code-first, documentation-later) lead to:
- **Agent hallucination**: AI agents guess implementation details
- **Inconsistency**: Different agents implement same feature differently
- **Rework**: Implementation doesn't match requirements
- **Lack of traceability**: Hard to trace code back to requirements

We need a workflow that:
- Provides **single source of truth** for intent
- Enables **autonomous agent development** without ambiguity
- Ensures **traceability** from requirements to implementation
- Supports **parallel development** by multiple agents

### Workflow Options

1. **Code-first**: Write code, document later (traditional)
2. **Test-Driven Development (TDD)**: Write tests, then implementation
3. **Spec-Driven Development (SDD)**: Write specs, then tests, then implementation

## Decision

We will use **Spec-Driven Development (SDD)** as the mandatory workflow for all features.

### Workflow

```
Spec → Plan → Tests → Implementation → Validation
```

1. **Spec**: Write or update specification in `specs/`
2. **Plan**: Create implementation plan referencing spec sections
3. **Tests**: Write failing tests that validate spec contracts
4. **Implementation**: Write code to pass tests and satisfy spec
5. **Validation**: Verify implementation matches spec

### Prime Directive

**NEVER generate code without checking specs/ first.**

## Rationale

**SDD advantages**:
1. **Single source of truth**: `specs/` directory contains all intent
2. **Agent-friendly**: Specs provide unambiguous contracts for AI agents
3. **Parallel development**: Multiple agents work on different specs without conflict
4. **Traceability**: Clear lineage from spec → test → code
5. **Prevents hallucination**: Agents cannot guess; must reference spec
6. **Facilitates review**: Humans review specs before implementation (cheaper than code review)
7. **Documentation**: Specs serve as living documentation

**TDD alone is insufficient**:
- Tests define "what" but not "why"
- Tests don't capture business context or constraints
- Agents may write tests that don't match requirements

**Code-first is incompatible with agent swarms**:
- Agents hallucinate implementation details
- No coordination between agents
- High rework rate

## Consequences

### Positive

- **Reduced hallucination**: Agents reference specs, not assumptions
- **Faster development**: Less rework, clearer requirements
- **Better coordination**: Multiple agents work from same spec
- **Improved quality**: Implementation validated against spec contracts
- **Living documentation**: Specs stay up-to-date (required for implementation)

### Negative

- **Upfront effort**: Writing specs takes time before coding
- **Spec maintenance**: Specs must be updated when requirements change
- **Learning curve**: Developers must learn SDD workflow

### Mitigations

1. **Templates**: Provide spec templates (`.specify/templates/`)
2. **Tooling**: Scripts to create/update specs (`.specify/scripts/`)
3. **Training**: Document SDD workflow in rules (`.cursor/rules/project-chimera.mdc`)

## Implementation

### Spec Structure

```
specs/
├── _meta.md              # Vision, constraints, principles
├── functional.md         # User stories, acceptance criteria
├── technical.md          # API contracts, database schema
├── api_endpoints.md      # REST API specifications
├── acceptance_criteria.md # Given/When/Then scenarios
├── mcp_servers.md        # MCP server specifications
├── openclaw_protocol.md  # OpenClaw integration protocol
└── rule_intent.md        # Rule categories and governance
```

### Spec Templates

See `.specify/templates/`:
- `spec-template.md` - Feature specification template
- `plan-template.md` - Implementation plan template
- `tasks-template.md` - Task breakdown template

### Workflow Scripts

See `.specify/scripts/bash/`:
- `create-new-feature.sh` - Create new feature spec
- `setup-plan.sh` - Generate implementation plan
- `update-agent-context.sh` - Update agent context with spec

### Rules

See `.cursor/rules/project-chimera.mdc`:
- **Prime Directive**: Never generate code without checking specs
- **Traceability**: Reference spec sections before writing code
- **Escalation**: If spec is ambiguous, clarify spec before implementing

### Example Workflow

1. **Operator requests feature**: "Add campaign budget alerts"

2. **Agent creates spec**: `specs/001-budget-alerts/spec.md`
   ```markdown
   # Feature: Campaign Budget Alerts
   
   ## User Story
   As a Network Operator, I need to receive alerts when campaign budget utilization exceeds 80%...
   
   ## API Contract
   GET /api/v1/campaigns/{id}/alerts
   Response: { "alerts": [...] }
   ```

3. **Agent creates plan**: `specs/001-budget-alerts/plan.md`
   ```markdown
   # Implementation Plan
   
   1. Add `budget_alerts` table to database
   2. Implement budget monitoring service
   3. Add alert endpoint to API
   4. Write tests for alert logic
   ```

4. **Agent writes tests**: `tests/test_budget_alerts.py`
   ```python
   def test_alert_triggered_at_80_percent():
       # Test that alert is created when budget reaches 80%
       ...
   ```

5. **Agent implements**: Code to pass tests and satisfy spec

6. **Agent validates**: Run tests, check spec alignment

## Alternatives Considered

### Code-First Development

**Pros**: Faster initial development
**Cons**: High rework rate, agent hallucination, no coordination
**Verdict**: Incompatible with agent swarms

### TDD Only

**Pros**: Tests define contracts
**Cons**: No business context, no "why", agents may write wrong tests
**Verdict**: Necessary but insufficient

### Documentation-After

**Pros**: No upfront effort
**Cons**: Documentation always out of date, no single source of truth
**Verdict**: Not suitable for autonomous agents

## References

- `.cursor/rules/project-chimera.mdc` - Prime Directive
- `specs/_meta.md` - Constraint: "Spec-first"
- `.specify/` - SDD tooling and templates
- `specs/rule_intent.md` - Rule categories (Prime Directive)
