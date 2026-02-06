# ADR-002: Model Context Protocol for External I/O

## Status

**Accepted** - 2026-02-06

## Context

Project Chimera agents need to interact with numerous external systems:
- Social media platforms (Twitter, Instagram, TikTok)
- News APIs and trend sources
- Vector databases (Weaviate) for memory
- Blockchain networks (via Coinbase AgentKit)
- Image/video generation services
- Agent social networks (OpenClaw)

Traditional approaches:
1. **Direct API integration**: Each agent calls platform APIs directly
2. **Service layer**: Centralized service layer wraps external APIs
3. **MCP (Model Context Protocol)**: Standardized protocol for AI-external world interaction

### Requirements

- **Standardization**: Consistent interface across diverse external systems
- **Decoupling**: Agent logic independent of external API changes
- **Governance**: Centralized control over external interactions (rate limiting, logging, dry-run)
- **Extensibility**: Easy to add new integrations without modifying agent core
- **Multi-modal**: Support for text, images, videos, structured data
- **Security**: Secrets management, audit logging

## Decision

We will use **Model Context Protocol (MCP)** as the **exclusive interface** for all agent-external world interactions.

### Rationale

**MCP advantages**:
1. **Standardization**: Universal protocol for AI-external world communication (like USB-C for AI)
2. **Three primitives**: Resources (read data), Tools (execute actions), Prompts (reasoning templates)
3. **Decoupling**: External API changes handled at MCP server level, not in agent code
4. **Governance layer**: MCP layer enforces rate limiting, logging, dry-run, HITL escalation
5. **Ecosystem**: Growing ecosystem of pre-built MCP servers (GitHub, Slack, databases)
6. **Future-proof**: As new platforms emerge, add MCP server without changing agent logic
7. **Multi-modal**: Native support for text, images, files, structured data

**Direct API integration drawbacks**:
- Tight coupling between agent logic and external APIs
- API changes break agent code
- No centralized governance or logging
- Difficult to test (requires mocking every API)

**Service layer drawbacks**:
- Custom abstraction layer requires maintenance
- Not standardized (reinventing the wheel)
- Limited ecosystem (no pre-built integrations)

## Consequences

### Positive

- **Agent simplicity**: Agents treat "Post to Twitter" and "Post to Instagram" as similar tool calls
- **Resilience**: Platform API changes handled at edge (MCP server), not in core
- **Testability**: Easy to mock MCP servers for testing
- **Governance**: Centralized rate limiting, logging, dry-run capabilities
- **Extensibility**: Add new platforms by deploying MCP server, no agent code changes
- **Audit trail**: All external interactions logged via MCP layer

### Negative

- **Dependency**: Requires MCP servers for all integrations (some may not exist yet)
- **Complexity**: Additional layer between agent and external world
- **Performance**: Slight latency overhead (typically <50ms)
- **Learning curve**: Developers must learn MCP protocol

### Mitigations

1. **Custom MCP servers**: Build custom servers for platforms without existing MCP support
2. **Performance**: Use stdio transport for local servers (minimal overhead), SSE for remote
3. **Documentation**: Comprehensive MCP server specs in `specs/mcp_servers.md`
4. **Fallback**: For critical operations, implement fallback to direct API if MCP server unavailable

## Implementation

### MCP Architecture

```
┌─────────────────────────────────────┐
│   Agent Core (Planner/Worker/Judge) │
│                                     │
│   ┌─────────────────────────────┐   │
│   │      MCP Client (Host)      │   │
│   └─────────────┬───────────────┘   │
└─────────────────┼───────────────────┘
                  │
      ┌───────────┼───────────┐
      │           │           │
      ▼           ▼           ▼
┌──────────┐ ┌──────────┐ ┌──────────┐
│   MCP    │ │   MCP    │ │   MCP    │
│  Server  │ │  Server  │ │  Server  │
│ (Twitter)│ │(Weaviate)│ │(Coinbase)│
└────┬─────┘ └────┬─────┘ └────┬─────┘
     │            │            │
     ▼            ▼            ▼
 Twitter API  Weaviate API  CDP API
```

### MCP Servers

See `specs/mcp_servers.md` for complete server specifications.

Core servers:
- `mcp-server-postgres` - Database operations
- `mcp-server-redis` - Cache and queue
- `mcp-server-weaviate` - Vector memory
- `mcp-server-twitter` - Social media
- `mcp-server-coinbase` - Crypto wallet
- `mcp-server-news` - Trend fetching
- `mcp-server-ideogram` - Image generation
- `mcp-server-openclaw` - Agent social network

### Configuration

MCP servers configured in `.cursor/mcp.json`:

```json
{
  "mcpServers": {
    "postgres": {
      "command": "uvx",
      "args": ["mcp-server-postgres", "postgresql://..."]
    },
    "twitter": {
      "command": "python",
      "args": ["-m", "mcp_server_twitter"],
      "env": {
        "TWITTER_API_KEY": "${TWITTER_API_KEY}"
      }
    }
  }
}
```

### Governance

MCP governance rules in `.cursor/rules/mcp-governance.mdc`:
- Only approved servers in `mcp.json`
- No secrets in repo (use environment variables)
- Audit log in `CONNECTION_LOG.md`
- Token rotation every 90 days

## Alternatives Considered

### Direct API Integration

**Pros**: Simpler, no additional layer
**Cons**: Tight coupling, no governance, difficult to test
**Verdict**: Not scalable or maintainable

### Custom Service Layer

**Pros**: Full control, custom abstractions
**Cons**: Reinventing the wheel, no ecosystem
**Verdict**: Too much maintenance overhead

### LangChain Tools

**Pros**: Existing ecosystem of tools
**Cons**: LangChain-specific, not standardized
**Verdict**: MCP is more universal and future-proof

## References

- MCP Specification: https://modelcontextprotocol.io/
- MCP Python SDK: https://github.com/modelcontextprotocol/python-sdk
- `specs/mcp_servers.md` - MCP server specifications
- `specs/_meta.md` - Constraint: "MCP-only external I/O"
- `.cursor/rules/mcp-governance.mdc` - MCP governance rules
