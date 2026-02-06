# Rule Intent Specification

**Document**: Meta-specification for agent governance rules
**Purpose**: Define rule categories, forbidden actions, escalation policies, and evolution phases
**Last updated**: 2026-02-06

---

## 1. Overview

This document defines the **intent and structure** of governance rules for AI agents working in the Project Chimera repository. It serves as a **meta-specification** that another agent could use to regenerate, extend, or validate the actual rule files in `.cursor/rules/`.

---

## 2. Rule Categories

### 2.1 Context Rules

**Purpose**: Establish project identity and domain knowledge

**Intent**: Ensure agents understand:
- What system they're working on (Project Chimera, autonomous influencer network)
- Core architectural patterns (MCP, FastRender Swarm, Agentic Commerce)
- Business model and strategic objectives
- Key terminology and acronyms

**Implementation**: `.cursor/rules/project-chimera.mdc`

**Required Elements**:
- Project name and type
- High-level architecture description
- Key constraints (spec-first, MCP-only I/O, HITL, multi-tenancy)
- References to authoritative documents (specs/, SRS)

---

### 2.2 Prime Directive Rules

**Purpose**: Prevent hallucination and ensure spec alignment

**Intent**: Enforce that agents:
- **NEVER** generate implementation code without checking specs first
- Always resolve intent from `specs/` directory
- Clarify or extend specs when ambiguous before implementing
- Maintain specs as single source of truth

**Implementation**: `.cursor/rules/project-chimera.mdc` (§ The Prime Directive)

**Forbidden Actions**:
1. Writing code without reading relevant spec sections
2. Guessing API contracts or database schemas
3. Implementing features not documented in specs
4. Making architectural decisions without spec ratification

**Escalation**: If spec is missing or ambiguous:
1. **DO NOT** implement based on assumptions
2. **DO** propose spec additions/clarifications
3. **DO** ask user for guidance if spec intent is unclear

---

### 2.3 Traceability Rules

**Purpose**: Maintain clear lineage from spec to implementation

**Intent**: Ensure agents:
- State which spec(s) they're implementing before writing code
- Reference specific sections (e.g., "specs/functional.md §A-2")
- Distinguish between Skills (runtime capabilities) and MCP Servers (external bridges)
- Include spec references in commit messages and PR descriptions

**Implementation**: `.cursor/rules/project-chimera.mdc` (§ Traceability)

**Required Workflow**:
1. **Before code**: "I am implementing [spec section] which requires [specific behavior]"
2. **During code**: Comments reference spec sections where appropriate
3. **After code**: Commit message includes spec reference

---

### 2.4 Git & GitHub Rules

**Purpose**: Define version control and collaboration workflows

**Intent**: Clarify when agents may:
- Commit changes autonomously
- Push to remote repository
- Create branches
- Open pull requests

**Implementation**: `.cursor/rules/git-github.mdc`

**Permissions**:
- **Agents MAY commit and push** when:
  - User explicitly requests ("commit and push", "save to GitHub")
  - Agent has completed a deliverable or coherent set of changes
- **Agents MUST request `git_write` permission** for any git state-modifying command

**Workflow**:
1. Stage changes (`git add`)
2. Commit with clear, concise message
3. Push to current branch (`git push`)

**Forbidden Actions**:
1. Force-push (`git push --force`) unless explicitly requested
2. Modifying git config
3. Interactive commands (`git rebase -i`, `git add -i`)
4. Committing without user request or completed deliverable

---

### 2.5 MCP Governance Rules

**Purpose**: Secure and govern external integrations

**Intent**: Enforce security and auditability for MCP servers

**Implementation**: `.cursor/rules/mcp-governance.mdc`

**Policies**:
1. **Approved Servers Only**: Only MCP servers in `.cursor/mcp.json` are allowed
2. **No Secrets in Repo**: Absolute prohibition on committing tokens, keys, or credentials
3. **Scoped Credentials**: Tokens must use least-privilege scopes
4. **Audit & Connection Log**: All MCP servers and token rotations recorded in `CONNECTION_LOG.md`
5. **Token Rotation**: Rotate production tokens every 90 days
6. **CI Validation**: CI must validate `mcp.json` format and fail on raw tokens

**Forbidden Actions**:
1. Committing raw secrets (PATs, tokens, private keys)
2. Adding MCP servers without PR approval
3. Using MCP servers not in approved list
4. Bypassing audit logging

**Escalation**:
- **Emergency Removal**: Open urgent PR, remove config, rotate tokens, notify owners
- **Suspected Compromise**: Immediately revoke token, open incident, notify security team

---

### 2.6 Testing & Quality Rules

**Purpose**: Maintain code quality and test coverage

**Intent**: Ensure agents:
- Write tests before or alongside implementation (TDD)
- Align tests with spec contracts
- Run tests before committing
- Fix introduced linter errors

**Implementation**: Implicit in project structure; could be formalized in `.cursor/rules/testing.mdc`

**Required Practices**:
1. **TDD**: Tests define "empty slot" for implementation
2. **Spec Alignment**: Tests reference API contracts and schemas from `specs/technical.md`
3. **No Real Credentials**: Tests use mocks, fixtures, or test credentials only
4. **Linter Compliance**: Run `make lint` before committing; fix introduced errors

**Forbidden Actions**:
1. Committing code that breaks existing tests
2. Skipping tests without justification
3. Using real credentials or secrets in tests
4. Ignoring linter errors introduced by changes

---

### 2.7 Security Rules

**Purpose**: Prevent security vulnerabilities and data leaks

**Intent**: Enforce secure coding practices

**Implementation**: `.cursor/rules/security.mdc` (to be created)

**Required Practices**:
1. **Input Validation**: Validate and sanitize all user inputs
2. **Output Encoding**: Encode outputs to prevent injection
3. **Authentication**: Verify authentication for all protected endpoints
4. **Authorization**: Check permissions before granting access
5. **Secrets Management**: Use environment variables or secrets manager
6. **Dependency Security**: Keep dependencies updated; scan for vulnerabilities
7. **Error Handling**: Never expose sensitive data in error messages

**Forbidden Actions**:
1. Hardcoding secrets, API keys, or passwords
2. Using `eval()` or similar dynamic code execution on user input
3. Disabling security features (CORS, CSRF, authentication)
4. Logging sensitive data (passwords, tokens, PII)
5. Using deprecated or vulnerable libraries

**Escalation**:
- **Security Issue Found**: Immediately notify user, do not commit vulnerable code
- **Dependency Vulnerability**: Upgrade to patched version or find alternative

---

### 2.8 Architecture & Design Rules

**Purpose**: Maintain architectural consistency

**Intent**: Ensure agents follow established patterns

**Implementation**: `.cursor/rules/architecture.mdc` (to be created)

**Patterns to Follow**:
1. **FastRender Swarm**: Planner / Worker / Judge roles for task coordination
2. **MCP-Only I/O**: All external interactions via MCP Resources and Tools
3. **Single-Orchestrator**: One human manages AI Manager Agents
4. **Multi-Tenancy**: Strict data isolation between tenants
5. **HITL**: Confidence-based routing for human review

**Forbidden Actions**:
1. Direct API calls to external services (bypass MCP layer)
2. Sharing data across tenant boundaries
3. Implementing monolithic agents (use swarm pattern)
4. Bypassing HITL for low-confidence or sensitive content

---

## 3. Escalation Policies

### 3.1 Escalation Levels

| Level | Trigger | Action |
|-------|---------|--------|
| **Info** | Clarification needed | Ask user for guidance |
| **Warning** | Ambiguous spec, potential issue | Propose solution, wait for approval |
| **Error** | Cannot proceed without user input | Stop work, explain blocker |
| **Critical** | Security issue, data loss risk | Immediately notify user, do not proceed |

### 3.2 Escalation Triggers

**Spec Ambiguity**:
- **Trigger**: Spec is vague, missing, or contradictory
- **Action**: Propose spec clarification or extension; do not implement based on assumptions

**Security Concern**:
- **Trigger**: Potential vulnerability, hardcoded secret, or insecure pattern
- **Action**: Immediately notify user; do not commit code

**Breaking Change**:
- **Trigger**: Change would break existing API contracts or tests
- **Action**: Confirm with user before proceeding

**Architectural Deviation**:
- **Trigger**: Proposed solution deviates from established patterns
- **Action**: Explain deviation, propose alternative, or get approval

---

## 4. Rule Evolution Phases

### Phase 1: Foundation (Current)

**Focus**: Establish core governance

**Rules**:
- Project context (what is Chimera)
- Prime Directive (spec-first)
- Traceability (reference specs)
- Git workflow (commit/push permissions)
- MCP governance (security, audit)

**Deliverables**:
- `.cursor/rules/project-chimera.mdc`
- `.cursor/rules/git-github.mdc`
- `.cursor/rules/mcp-governance.mdc`
- `.cursor/rules/agents.md`

---

### Phase 2: Quality & Security (Next)

**Focus**: Enforce quality standards and security practices

**New Rules**:
- Testing & TDD requirements
- Security best practices
- Code review standards
- Dependency management

**Deliverables**:
- `.cursor/rules/testing.mdc`
- `.cursor/rules/security.mdc`
- `.cursor/rules/code-review.mdc`

---

### Phase 3: Architecture & Patterns (Future)

**Focus**: Enforce architectural patterns and design principles

**New Rules**:
- FastRender Swarm implementation patterns
- MCP server design guidelines
- Database schema evolution
- API versioning and deprecation

**Deliverables**:
- `.cursor/rules/architecture.mdc`
- `.cursor/rules/mcp-design.mdc`
- `.cursor/rules/database.mdc`

---

### Phase 4: Collaboration & Workflow (Future)

**Focus**: Multi-agent collaboration and workflow automation

**New Rules**:
- Agent-to-agent communication protocols
- Swarm coordination patterns
- Conflict resolution
- Automated refactoring guidelines

**Deliverables**:
- `.cursor/rules/collaboration.mdc`
- `.cursor/rules/swarm-patterns.mdc`

---

## 5. Rule Validation

### 5.1 Rule Completeness Checklist

A complete rule file MUST include:

- [ ] **Purpose**: Why this rule exists
- [ ] **Scope**: What it applies to (files, actions, agents)
- [ ] **Required Practices**: What agents MUST do
- [ ] **Forbidden Actions**: What agents MUST NOT do
- [ ] **Escalation Policy**: What to do when rule cannot be followed
- [ ] **Examples**: Concrete examples of good and bad behavior

### 5.2 Rule Consistency Checks

Rules MUST be:
- **Non-contradictory**: No rule conflicts with another
- **Actionable**: Clear, specific, implementable
- **Verifiable**: Can be checked automatically or manually
- **Maintainable**: Easy to update as project evolves

### 5.3 Automated Validation

CI pipeline SHOULD validate:
1. All rule files parse correctly (Markdown, frontmatter)
2. No contradictory rules (e.g., "always commit" vs "never commit")
3. All referenced files exist (e.g., `specs/functional.md`)
4. Rule coverage for all major categories

---

## 6. Rule Generation Template

When creating a new rule file, use this template:

```markdown
---
description: [Brief description of rule purpose]
alwaysApply: true | false
---

# [Rule Category Name]

[Brief introduction explaining why this rule exists]

---

## Purpose

[Detailed explanation of what this rule governs]

---

## Scope

**Applies to**:
- [Files, directories, or actions this rule covers]

**Does not apply to**:
- [Exceptions or exclusions]

---

## Required Practices

Agents MUST:
1. [Required action 1]
2. [Required action 2]
...

---

## Forbidden Actions

Agents MUST NOT:
1. [Forbidden action 1]
2. [Forbidden action 2]
...

---

## Escalation Policy

When [trigger condition]:
1. [Step 1]
2. [Step 2]
...

---

## Examples

### Good Example

[Concrete example of following the rule]

### Bad Example

[Concrete example of violating the rule]

---

## Related Rules

- [Link to related rule file]
- [Link to spec or doc]
```

---

## 7. Rule Maintenance

### 7.1 Review Cadence

- **Weekly**: Review rule violations in agent logs
- **Monthly**: Update rules based on new patterns or issues
- **Quarterly**: Comprehensive rule audit and refactoring

### 7.2 Rule Deprecation

To deprecate a rule:
1. Mark as `deprecated: true` in frontmatter
2. Add deprecation notice with replacement rule
3. Keep deprecated rule for 1 release cycle
4. Remove after confirming no violations

### 7.3 Rule Versioning

Rules follow semantic versioning:
- **Major**: Breaking change (new forbidden action, removed permission)
- **Minor**: New guidance, clarification, or example
- **Patch**: Typo fix, formatting, or link update

---

## 8. Implementation Checklist

To implement this rule intent specification:

- [ ] Create missing rule files (testing.mdc, security.mdc, architecture.mdc)
- [ ] Add frontmatter to all rule files (description, alwaysApply)
- [ ] Ensure all rules follow template structure
- [ ] Add examples to each rule file
- [ ] Create CI validation for rule consistency
- [ ] Document rule evolution roadmap
- [ ] Train agents on rule categories and escalation policies

---

## References

- `.cursor/rules/` - Actual rule implementations
- `specs/_meta.md` - Project constraints and principles
- `CONNECTION_LOG.md` - MCP audit log
- `.coderabbit.yaml` - AI review policy
