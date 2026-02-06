# OpenClaw Integration Plan

**Document**: How Chimera publishes Availability / Status to the OpenClaw Agent Social Network  
**Status**: Optional integration; placeholder for protocol alignment  
**Last updated**: 2025-02-04

---

## Context

OpenClaw and the “Agent Social Network” describe a world where AI agents communicate and coordinate with other agents (not only humans). Chimera agents may need to:

- Publish their **availability** or **status** so other agents can discover or request collaboration.
- Consume **social protocols** (e.g. discovery, handshake, capability negotiation) to interact with other agents on the network.

This document outlines how Chimera could integrate with such a network without committing to a specific protocol until the OpenClaw specs are stable.

---

## Integration Directions

### 1. Status / Availability Feed

- **Intent**: Chimera Orchestrator (or each agent) publishes a machine-readable status (e.g. “available”, “busy”, “maintenance”) and optional capability set.
- **Possible mechanisms**:
  - MCP Resource exposed by Chimera: e.g. `chimera://agent/{id}/status` or `chimera://fleet/status`.
  - Webhook or callback URL registered with a central directory (if OpenClaw defines one).
  - Lightweight REST or MCP endpoint that returns a JSON status contract.

### 2. Social Protocols for Agent-to-Agent

- **Intent**: Define or adopt protocols for:
  - **Discovery**: How other agents find Chimera agents (by niche, capability, tenant).
  - **Handshake**: How two agents agree to interact (e.g. capability exchange, auth).
  - **Negotiation**: How agents agree on tasks (e.g. “Agent A requests trend data from Agent B”).
- **Alignment**: When OpenClaw or community specs (e.g. MoltBook, agent social graphs) are available, align Chimera’s MCP Resources/Tools and any new endpoints to those specs.

### 3. Implementation Placeholder

- No implementation code is written until:
  - A ratified spec exists in `specs/` for the chosen protocol, and
  - The technical contract (e.g. JSON schema for status, discovery, handshake) is added to `specs/technical.md`.
- **Next steps**: Monitor OpenClaw / MoltBook documentation; add a dedicated `specs/openclaw_protocol.md` (or section in `technical.md`) once a concrete protocol is selected, then implement behind MCP or a small Orchestrator API.

---

## Traceability

- **Functional**: User story A-* in `specs/functional.md` (e.g. fetch trends, publish) can later reference “OpenClaw discovery” or “agent-to-agent handshake” when those become requirements.
- **Technical**: Any new endpoints or MCP Resources for OpenClaw MUST be added to `specs/technical.md` with JSON contracts before implementation.
