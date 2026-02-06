# MCP Servers Specification

**Document**: Comprehensive MCP server definitions with tools, schemas, and auth details
**Purpose**: Enable autonomous agent use of all external integrations
**Last updated**: 2026-02-06

---

## 1. Overview

This document defines all MCP servers required for Project Chimera, including:
- Server configuration and connection details
- Tools (executable functions) with input/output schemas
- Resources (read-only data sources) with access patterns
- Prompts (reusable templates) for reasoning
- Authentication and authorization requirements

---

## 2. MCP Server Registry

### 2.1 Core Servers (Required)

| Server Name | Purpose | Transport | Status |
|------------|---------|-----------|--------|
| `mcp-server-postgres` | Database operations | stdio | Required |
| `mcp-server-redis` | Cache and queue management | stdio | Required |
| `mcp-server-weaviate` | Vector memory storage | stdio | Required |
| `mcp-server-twitter` | Twitter/X social actions | stdio | Optional |
| `mcp-server-instagram` | Instagram social actions | stdio | Optional |
| `mcp-server-coinbase` | Crypto wallet operations | stdio | Required |
| `mcp-server-news` | News and trend fetching | stdio | Required |
| `mcp-server-ideogram` | Image generation | SSE | Optional |
| `mcp-server-openclaw` | Agent social network | SSE | Optional |

### 2.2 Development Servers

| Server Name | Purpose | Transport | Status |
|------------|---------|-----------|--------|
| `tenxfeedbackanalytics` | IDE telemetry | HTTPS | Active |
| `github` | Version control | HTTPS | Active |
| `cursor-ide-browser` | Frontend testing | stdio | Active |

---

## 3. Server Specifications

---

## 3.1 mcp-server-postgres

**Purpose**: Database operations for transactional data (agents, campaigns, tasks, content)

**Transport**: stdio

**Configuration**:
```json
{
  "command": "uvx",
  "args": ["mcp-server-postgres", "postgresql://chimera:${DB_PASSWORD}@localhost:5432/chimera"],
  "env": {
    "DB_PASSWORD": "${DATABASE_PASSWORD}"
  }
}
```

### Tools

#### 3.1.1 `query_database`

**Description**: Execute read-only SQL query

**Input Schema**:
```json
{
  "type": "object",
  "properties": {
    "query": {
      "type": "string",
      "description": "SQL SELECT query (read-only)"
    },
    "parameters": {
      "type": "array",
      "items": {"type": "string"},
      "description": "Query parameters for safe parameterization"
    }
  },
  "required": ["query"]
}
```

**Output Schema**:
```json
{
  "type": "object",
  "properties": {
    "rows": {
      "type": "array",
      "items": {"type": "object"},
      "description": "Query result rows"
    },
    "row_count": {"type": "integer"},
    "execution_time_ms": {"type": "number"}
  }
}
```

**Example**:
```json
{
  "query": "SELECT * FROM agents WHERE tenant_id = $1 LIMIT 10",
  "parameters": ["tenant-123"]
}
```

---

#### 3.1.2 `insert_record`

**Description**: Insert a new record into a table

**Input Schema**:
```json
{
  "type": "object",
  "properties": {
    "table": {
      "type": "string",
      "enum": ["agents", "campaigns", "tasks", "content_assets", "video_metadata"]
    },
    "data": {
      "type": "object",
      "description": "Record data matching table schema"
    }
  },
  "required": ["table", "data"]
}
```

**Output Schema**:
```json
{
  "type": "object",
  "properties": {
    "id": {"type": "string", "description": "UUID of inserted record"},
    "created_at": {"type": "string", "format": "date-time"}
  }
}
```

---

#### 3.1.3 `update_record`

**Description**: Update an existing record

**Input Schema**:
```json
{
  "type": "object",
  "properties": {
    "table": {"type": "string"},
    "id": {"type": "string", "format": "uuid"},
    "data": {"type": "object"},
    "tenant_id": {"type": "string", "description": "For authorization check"}
  },
  "required": ["table", "id", "data", "tenant_id"]
}
```

**Output Schema**:
```json
{
  "type": "object",
  "properties": {
    "updated": {"type": "boolean"},
    "updated_at": {"type": "string", "format": "date-time"}
  }
}
```

---

### Resources

#### 3.1.4 `postgres://schema/{table}`

**Description**: Get table schema definition

**URI Pattern**: `postgres://schema/agents`, `postgres://schema/campaigns`

**Output**: JSON Schema for table

---

### Authentication

- **Method**: Connection string with username/password
- **Credentials**: Stored in environment variable `DATABASE_PASSWORD`
- **Permissions**: Read/write access to `chimera` database
- **Rotation**: Every 90 days

---

## 3.2 mcp-server-redis

**Purpose**: Cache management, task queuing, and short-term memory

**Transport**: stdio

**Configuration**:
```json
{
  "command": "npx",
  "args": ["-y", "mcp-server-redis", "redis://localhost:6379"],
  "env": {
    "REDIS_PASSWORD": "${REDIS_PASSWORD}"
  }
}
```

### Tools

#### 3.2.1 `redis_get`

**Input Schema**:
```json
{
  "type": "object",
  "properties": {
    "key": {"type": "string"}
  },
  "required": ["key"]
}
```

**Output Schema**:
```json
{
  "type": "object",
  "properties": {
    "value": {"type": "string", "nullable": true},
    "exists": {"type": "boolean"}
  }
}
```

---

#### 3.2.2 `redis_set`

**Input Schema**:
```json
{
  "type": "object",
  "properties": {
    "key": {"type": "string"},
    "value": {"type": "string"},
    "ttl_seconds": {"type": "integer", "description": "Time to live (optional)"}
  },
  "required": ["key", "value"]
}
```

**Output Schema**:
```json
{
  "type": "object",
  "properties": {
    "success": {"type": "boolean"}
  }
}
```

---

#### 3.2.3 `redis_push_queue`

**Description**: Push task to queue (LPUSH)

**Input Schema**:
```json
{
  "type": "object",
  "properties": {
    "queue_name": {
      "type": "string",
      "enum": ["task_queue", "review_queue", "hitl_queue"]
    },
    "payload": {"type": "object"}
  },
  "required": ["queue_name", "payload"]
}
```

**Output Schema**:
```json
{
  "type": "object",
  "properties": {
    "queue_length": {"type": "integer"}
  }
}
```

---

#### 3.2.4 `redis_pop_queue`

**Description**: Pop task from queue (BRPOP with timeout)

**Input Schema**:
```json
{
  "type": "object",
  "properties": {
    "queue_name": {"type": "string"},
    "timeout_seconds": {"type": "integer", "default": 5}
  },
  "required": ["queue_name"]
}
```

**Output Schema**:
```json
{
  "type": "object",
  "properties": {
    "payload": {"type": "object", "nullable": true},
    "queue_name": {"type": "string"}
  }
}
```

---

### Resources

#### 3.2.5 `redis://queue/{queue_name}/length`

**Description**: Get current queue depth

**URI Pattern**: `redis://queue/task_queue/length`

**Output**: Integer (queue length)

---

### Authentication

- **Method**: Password authentication
- **Credentials**: Environment variable `REDIS_PASSWORD`
- **Permissions**: Full read/write access
- **Rotation**: Every 90 days

---

## 3.3 mcp-server-weaviate

**Purpose**: Vector database for semantic memory and RAG

**Transport**: stdio

**Configuration**:
```json
{
  "command": "python",
  "args": ["-m", "mcp_server_weaviate", "--url", "http://localhost:8080", "--api-key", "${WEAVIATE_API_KEY}"]
}
```

### Tools

#### 3.3.1 `search_memory`

**Description**: Semantic search for relevant memories

**Input Schema**:
```json
{
  "type": "object",
  "properties": {
    "agent_id": {"type": "string", "format": "uuid"},
    "query": {"type": "string", "description": "Natural language query"},
    "limit": {"type": "integer", "default": 5, "maximum": 20},
    "memory_type": {
      "type": "string",
      "enum": ["episodic", "semantic", "procedural"],
      "default": "semantic"
    }
  },
  "required": ["agent_id", "query"]
}
```

**Output Schema**:
```json
{
  "type": "object",
  "properties": {
    "memories": {
      "type": "array",
      "items": {
        "type": "object",
        "properties": {
          "id": {"type": "string"},
          "content": {"type": "string"},
          "similarity_score": {"type": "number", "minimum": 0, "maximum": 1},
          "created_at": {"type": "string", "format": "date-time"},
          "metadata": {"type": "object"}
        }
      }
    }
  }
}
```

---

#### 3.3.2 `store_memory`

**Description**: Store new memory vector

**Input Schema**:
```json
{
  "type": "object",
  "properties": {
    "agent_id": {"type": "string", "format": "uuid"},
    "content": {"type": "string"},
    "memory_type": {"type": "string", "enum": ["episodic", "semantic", "procedural"]},
    "metadata": {
      "type": "object",
      "properties": {
        "source": {"type": "string"},
        "importance": {"type": "number", "minimum": 0, "maximum": 1}
      }
    }
  },
  "required": ["agent_id", "content", "memory_type"]
}
```

**Output Schema**:
```json
{
  "type": "object",
  "properties": {
    "memory_id": {"type": "string", "format": "uuid"},
    "stored_at": {"type": "string", "format": "date-time"}
  }
}
```

---

#### 3.3.3 `get_persona`

**Description**: Retrieve agent persona from vector store

**Input Schema**:
```json
{
  "type": "object",
  "properties": {
    "agent_id": {"type": "string", "format": "uuid"}
  },
  "required": ["agent_id"]
}
```

**Output Schema**:
```json
{
  "type": "object",
  "properties": {
    "persona": {
      "type": "object",
      "properties": {
        "name": {"type": "string"},
        "backstory": {"type": "string"},
        "voice_traits": {"type": "array", "items": {"type": "string"}},
        "core_beliefs": {"type": "array", "items": {"type": "string"}},
        "directives": {"type": "array", "items": {"type": "string"}}
      }
    }
  }
}
```

---

### Resources

#### 3.3.4 `weaviate://agent/{agent_id}/memories/recent`

**Description**: Get recent memories for agent (last 24 hours)

**URI Pattern**: `weaviate://agent/agent-123/memories/recent`

**Output**: Array of memory objects

---

### Authentication

- **Method**: API key
- **Credentials**: Environment variable `WEAVIATE_API_KEY`
- **Permissions**: Read/write to agent memory collections
- **Rotation**: Every 90 days

---

## 3.4 mcp-server-coinbase

**Purpose**: Crypto wallet operations via Coinbase AgentKit

**Transport**: stdio

**Configuration**:
```json
{
  "command": "python",
  "args": ["-m", "mcp_server_coinbase"],
  "env": {
    "CDP_API_KEY_NAME": "${CDP_API_KEY_NAME}",
    "CDP_API_KEY_PRIVATE_KEY": "${CDP_API_KEY_PRIVATE_KEY}"
  }
}
```

### Tools

#### 3.4.1 `get_balance`

**Input Schema**:
```json
{
  "type": "object",
  "properties": {
    "agent_id": {"type": "string", "format": "uuid"},
    "asset": {"type": "string", "enum": ["ETH", "USDC"], "default": "USDC"}
  },
  "required": ["agent_id"]
}
```

**Output Schema**:
```json
{
  "type": "object",
  "properties": {
    "agent_id": {"type": "string"},
    "wallet_address": {"type": "string"},
    "balance": {"type": "string", "description": "Balance as string to avoid precision loss"},
    "asset": {"type": "string"},
    "network": {"type": "string", "enum": ["base", "ethereum"]},
    "last_updated": {"type": "string", "format": "date-time"}
  }
}
```

---

#### 3.4.2 `native_transfer`

**Description**: Transfer ETH or USDC to another wallet

**Input Schema**:
```json
{
  "type": "object",
  "properties": {
    "agent_id": {"type": "string", "format": "uuid"},
    "to_address": {"type": "string", "pattern": "^0x[a-fA-F0-9]{40}$"},
    "amount": {"type": "string", "description": "Amount as string (e.g., '10.5')"},
    "asset": {"type": "string", "enum": ["ETH", "USDC"], "default": "USDC"},
    "purpose": {"type": "string", "description": "Transaction purpose for audit"}
  },
  "required": ["agent_id", "to_address", "amount", "purpose"]
}
```

**Output Schema**:
```json
{
  "type": "object",
  "properties": {
    "transaction_id": {"type": "string", "format": "uuid"},
    "tx_hash": {"type": "string"},
    "status": {"type": "string", "enum": ["pending", "confirmed", "failed"]},
    "from_address": {"type": "string"},
    "to_address": {"type": "string"},
    "amount": {"type": "string"},
    "asset": {"type": "string"},
    "network": {"type": "string"},
    "created_at": {"type": "string", "format": "date-time"}
  }
}
```

---

#### 3.4.3 `deploy_token`

**Description**: Deploy ERC-20 token contract

**Input Schema**:
```json
{
  "type": "object",
  "properties": {
    "agent_id": {"type": "string", "format": "uuid"},
    "token_name": {"type": "string"},
    "token_symbol": {"type": "string", "maxLength": 5},
    "initial_supply": {"type": "string"},
    "decimals": {"type": "integer", "default": 18}
  },
  "required": ["agent_id", "token_name", "token_symbol", "initial_supply"]
}
```

**Output Schema**:
```json
{
  "type": "object",
  "properties": {
    "contract_address": {"type": "string"},
    "tx_hash": {"type": "string"},
    "token_name": {"type": "string"},
    "token_symbol": {"type": "string"},
    "deployed_at": {"type": "string", "format": "date-time"}
  }
}
```

---

### Authentication

- **Method**: CDP API key pair
- **Credentials**: Environment variables `CDP_API_KEY_NAME`, `CDP_API_KEY_PRIVATE_KEY`
- **Permissions**: Wallet creation, transaction signing
- **Rotation**: Every 90 days
- **Security**: Private keys stored in AWS Secrets Manager, injected at runtime

---

## 3.5 mcp-server-news

**Purpose**: Fetch news and trends from multiple sources

**Transport**: stdio

**Configuration**:
```json
{
  "command": "python",
  "args": ["-m", "mcp_server_news"],
  "env": {
    "NEWS_API_KEY": "${NEWS_API_KEY}"
  }
}
```

### Tools

#### 3.5.1 `fetch_news`

**Input Schema**:
```json
{
  "type": "object",
  "properties": {
    "query": {"type": "string", "description": "Search query"},
    "category": {
      "type": "string",
      "enum": ["business", "entertainment", "health", "science", "sports", "technology"]
    },
    "language": {"type": "string", "default": "en"},
    "country": {"type": "string", "default": "us"},
    "limit": {"type": "integer", "default": 10, "maximum": 100}
  },
  "required": ["query"]
}
```

**Output Schema**: Matches Trend Data schema from `specs/technical.md` §1.3

```json
{
  "type": "object",
  "properties": {
    "articles": {
      "type": "array",
      "items": {
        "type": "object",
        "properties": {
          "source_id": {"type": "string"},
          "source_type": {"type": "string", "const": "news"},
          "title": {"type": "string"},
          "summary": {"type": "string"},
          "url": {"type": "string", "format": "uri"},
          "published_at": {"type": "string", "format": "date-time"},
          "relevance_score": {"type": "number", "minimum": 0, "maximum": 1},
          "topics": {"type": "array", "items": {"type": "string"}}
        }
      }
    }
  }
}
```

---

### Resources

#### 3.5.2 `news://latest/{category}`

**Description**: Get latest news for category

**URI Pattern**: `news://latest/technology`, `news://latest/business`

**Output**: Array of news articles

---

#### 3.5.3 `news://trending/{region}`

**Description**: Get trending topics for region

**URI Pattern**: `news://trending/ethiopia`, `news://trending/global`

**Output**: Array of trending topics with article counts

---

### Authentication

- **Method**: API key
- **Credentials**: Environment variable `NEWS_API_KEY`
- **Permissions**: Read-only access to news API
- **Rate Limit**: 1000 requests/day
- **Rotation**: Every 90 days

---

## 3.6 mcp-server-twitter

**Purpose**: Twitter/X social media operations

**Transport**: stdio

**Configuration**:
```json
{
  "command": "python",
  "args": ["-m", "mcp_server_twitter"],
  "env": {
    "TWITTER_API_KEY": "${TWITTER_API_KEY}",
    "TWITTER_API_SECRET": "${TWITTER_API_SECRET}",
    "TWITTER_ACCESS_TOKEN": "${TWITTER_ACCESS_TOKEN}",
    "TWITTER_ACCESS_SECRET": "${TWITTER_ACCESS_SECRET}"
  }
}
```

### Tools

#### 3.6.1 `post_tweet`

**Input Schema**:
```json
{
  "type": "object",
  "properties": {
    "agent_id": {"type": "string", "format": "uuid"},
    "text": {"type": "string", "maxLength": 280},
    "media_urls": {"type": "array", "items": {"type": "string", "format": "uri"}, "maxItems": 4},
    "reply_to_tweet_id": {"type": "string", "description": "For replies"}
  },
  "required": ["agent_id", "text"]
}
```

**Output Schema**:
```json
{
  "type": "object",
  "properties": {
    "tweet_id": {"type": "string"},
    "url": {"type": "string", "format": "uri"},
    "created_at": {"type": "string", "format": "date-time"}
  }
}
```

---

#### 3.6.2 `like_tweet`

**Input Schema**:
```json
{
  "type": "object",
  "properties": {
    "agent_id": {"type": "string", "format": "uuid"},
    "tweet_id": {"type": "string"}
  },
  "required": ["agent_id", "tweet_id"]
}
```

**Output Schema**:
```json
{
  "type": "object",
  "properties": {
    "success": {"type": "boolean"},
    "liked_at": {"type": "string", "format": "date-time"}
  }
}
```

---

### Resources

#### 3.6.3 `twitter://mentions/{agent_id}/recent`

**Description**: Get recent mentions for agent

**URI Pattern**: `twitter://mentions/agent-123/recent`

**Output**: Array of tweet objects with mention data

---

### Authentication

- **Method**: OAuth 1.0a (4-legged)
- **Credentials**: API key, API secret, Access token, Access secret
- **Permissions**: Read, write, and direct messages
- **Rate Limit**: 300 tweets/3 hours per agent
- **Rotation**: Every 90 days

---

## 3.7 mcp-server-ideogram

**Purpose**: AI image generation

**Transport**: SSE (Server-Sent Events)

**Configuration**:
```json
{
  "url": "https://api.ideogram.ai/mcp",
  "headers": {
    "Authorization": "Bearer ${IDEOGRAM_API_KEY}"
  }
}
```

### Tools

#### 3.7.1 `generate_image`

**Input Schema**:
```json
{
  "type": "object",
  "properties": {
    "prompt": {"type": "string", "maxLength": 1000},
    "character_reference_id": {"type": "string", "description": "For character consistency"},
    "style": {"type": "string", "enum": ["realistic", "anime", "3d", "illustration"]},
    "aspect_ratio": {"type": "string", "enum": ["1:1", "16:9", "9:16", "4:3"], "default": "1:1"},
    "negative_prompt": {"type": "string"}
  },
  "required": ["prompt"]
}
```

**Output Schema**:
```json
{
  "type": "object",
  "properties": {
    "image_id": {"type": "string"},
    "image_url": {"type": "string", "format": "uri"},
    "width": {"type": "integer"},
    "height": {"type": "integer"},
    "generated_at": {"type": "string", "format": "date-time"}
  }
}
```

---

### Authentication

- **Method**: Bearer token
- **Credentials**: Environment variable `IDEOGRAM_API_KEY`
- **Permissions**: Image generation
- **Rate Limit**: 100 images/day per API key
- **Cost**: $0.08 per image
- **Rotation**: Every 90 days

---

## 3.8 mcp-server-openclaw

**Purpose**: Agent social network integration

**Transport**: SSE

**Configuration**:
```json
{
  "url": "https://api.openclaw.network/v1/mcp",
  "headers": {
    "Authorization": "Bearer ${OPENCLAW_ACCESS_TOKEN}"
  }
}
```

### Tools

See `specs/openclaw_protocol.md` for complete tool definitions.

Key tools:
- `send_message` - Send message to another agent
- `search_agents` - Discover agents by capability
- `create_collaboration` - Propose collaboration

---

### Authentication

- **Method**: OAuth 2.0 with JWT
- **Credentials**: Environment variable `OPENCLAW_ACCESS_TOKEN`
- **Permissions**: Agent registration, messaging, collaboration
- **Rotation**: Access token expires every 24 hours, refresh token every 30 days

---

## 4. MCP Configuration File

Complete `.cursor/mcp.json` with all servers:

```json
{
  "mcpServers": {
    "postgres": {
      "command": "uvx",
      "args": ["mcp-server-postgres", "postgresql://chimera:${DATABASE_PASSWORD}@localhost:5432/chimera"]
    },
    "redis": {
      "command": "npx",
      "args": ["-y", "mcp-server-redis", "redis://localhost:6379"]
    },
    "weaviate": {
      "command": "python",
      "args": ["-m", "mcp_server_weaviate", "--url", "http://localhost:8080", "--api-key", "${WEAVIATE_API_KEY}"]
    },
    "coinbase": {
      "command": "python",
      "args": ["-m", "mcp_server_coinbase"],
      "env": {
        "CDP_API_KEY_NAME": "${CDP_API_KEY_NAME}",
        "CDP_API_KEY_PRIVATE_KEY": "${CDP_API_KEY_PRIVATE_KEY}"
      }
    },
    "news": {
      "command": "python",
      "args": ["-m", "mcp_server_news"],
      "env": {
        "NEWS_API_KEY": "${NEWS_API_KEY}"
      }
    },
    "twitter": {
      "command": "python",
      "args": ["-m", "mcp_server_twitter"],
      "env": {
        "TWITTER_API_KEY": "${TWITTER_API_KEY}",
        "TWITTER_API_SECRET": "${TWITTER_API_SECRET}",
        "TWITTER_ACCESS_TOKEN": "${TWITTER_ACCESS_TOKEN}",
        "TWITTER_ACCESS_SECRET": "${TWITTER_ACCESS_SECRET}"
      }
    },
    "ideogram": {
      "url": "https://api.ideogram.ai/mcp",
      "headers": {
        "Authorization": "Bearer ${IDEOGRAM_API_KEY}"
      }
    },
    "openclaw": {
      "url": "https://api.openclaw.network/v1/mcp",
      "headers": {
        "Authorization": "Bearer ${OPENCLAW_ACCESS_TOKEN}"
      }
    },
    "tenxfeedbackanalytics": {
      "name": "tenxanalysismcp",
      "url": "https://mcppulse.10academy.org/proxy",
      "headers": {
        "X-Device": "mac",
        "X-Coding-Tool": "cursor"
      }
    },
    "github": {
      "url": "https://api.githubcopilot.com/mcp/",
      "headers": {
        "Authorization": "Bearer {{MCP_GITHUB_TOKEN}}"
      }
    }
  }
}
```

---

## 5. Environment Variables

Required environment variables for all MCP servers:

```bash
# Database
DATABASE_PASSWORD=<postgres-password>

# Redis
REDIS_PASSWORD=<redis-password>

# Weaviate
WEAVIATE_API_KEY=<weaviate-api-key>

# Coinbase AgentKit
CDP_API_KEY_NAME=<cdp-api-key-name>
CDP_API_KEY_PRIVATE_KEY=<cdp-private-key>

# News API
NEWS_API_KEY=<newsapi-key>

# Twitter
TWITTER_API_KEY=<twitter-api-key>
TWITTER_API_SECRET=<twitter-api-secret>
TWITTER_ACCESS_TOKEN=<twitter-access-token>
TWITTER_ACCESS_SECRET=<twitter-access-secret>

# Image Generation
IDEOGRAM_API_KEY=<ideogram-api-key>

# OpenClaw
OPENCLAW_ACCESS_TOKEN=<openclaw-jwt-token>

# GitHub (for development)
MCP_GITHUB_TOKEN=<github-pat>
```

---

## 6. Security Best Practices

1. **Never commit credentials**: All tokens/keys in environment variables
2. **Use secrets manager**: AWS Secrets Manager or HashiCorp Vault for production
3. **Rotate regularly**: All credentials rotated every 90 days
4. **Least privilege**: Each MCP server has minimal required permissions
5. **Audit logging**: All MCP tool calls logged with agent_id, timestamp, and result
6. **Rate limiting**: Respect API rate limits to avoid account suspension
7. **Error handling**: Gracefully handle MCP server unavailability

---

## References

- MCP Specification: https://modelcontextprotocol.io/docs
- Coinbase AgentKit: https://docs.cdp.coinbase.com/agentkit
- `.cursor/mcp.json` - MCP configuration file
- `CONNECTION_LOG.md` - MCP connection audit log
- `.cursor/rules/mcp-governance.mdc` - MCP governance rules
