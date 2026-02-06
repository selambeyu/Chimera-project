# API Endpoints Specification

**Document**: Explicit REST API contracts for Project Chimera backend
**Source**: Project Chimera SRS §4 (Functional Requirements)
**Last updated**: 2026-02-06

---

## Base URL

- **Development**: `http://localhost:8000/api/v1`
- **Production**: `https://api.chimera.aiqem.tech/api/v1`

---

## 1. Campaign Management

### 1.1 Create Campaign Goal

**Endpoint**: `POST /campaigns`

**Description**: Network Operator submits a natural-language campaign goal (FR: OP-1)

**Request**:
```json
{
  "goal_description": "string (required, 10-500 chars)",
  "target_platforms": ["twitter", "instagram", "threads"],
  "priority": "high | medium | low",
  "budget_usdc": 100.0,
  "start_date": "2026-02-10T00:00:00Z",
  "end_date": "2026-03-10T00:00:00Z",
  "tenant_id": "uuid-v4-string"
}
```

**Response** (201 Created):
```json
{
  "campaign_id": "uuid-v4-string",
  "status": "planning",
  "task_tree_url": "/campaigns/{campaign_id}/tasks",
  "created_at": "ISO8601 timestamp"
}
```

**Errors**:
- `400 Bad Request`: Invalid goal_description or budget
- `401 Unauthorized`: Missing or invalid auth token
- `403 Forbidden`: Tenant quota exceeded
- `422 Unprocessable Entity`: Validation errors

---

### 1.2 Get Campaign Status

**Endpoint**: `GET /campaigns/{campaign_id}`

**Description**: Retrieve campaign details and current status

**Response** (200 OK):
```json
{
  "campaign_id": "uuid-v4-string",
  "goal_description": "string",
  "status": "planning | active | paused | completed | failed",
  "progress": {
    "total_tasks": 42,
    "completed_tasks": 15,
    "pending_tasks": 20,
    "failed_tasks": 7
  },
  "budget": {
    "allocated_usdc": 100.0,
    "spent_usdc": 23.45,
    "remaining_usdc": 76.55
  },
  "metrics": {
    "posts_published": 12,
    "engagement_rate": 0.045,
    "hitl_escalations": 3
  },
  "created_at": "ISO8601",
  "updated_at": "ISO8601"
}
```

**Errors**:
- `404 Not Found`: Campaign does not exist
- `403 Forbidden`: Not authorized for this tenant

---

### 1.3 List Campaigns

**Endpoint**: `GET /campaigns`

**Query Parameters**:
- `tenant_id` (required): Filter by tenant
- `status` (optional): Filter by status
- `page` (optional, default=1): Page number
- `limit` (optional, default=20, max=100): Items per page

**Response** (200 OK):
```json
{
  "campaigns": [
    {
      "campaign_id": "uuid",
      "goal_description": "string",
      "status": "active",
      "created_at": "ISO8601"
    }
  ],
  "pagination": {
    "page": 1,
    "limit": 20,
    "total": 42,
    "pages": 3
  }
}
```

---

### 1.4 Update Campaign

**Endpoint**: `PATCH /campaigns/{campaign_id}`

**Request**:
```json
{
  "status": "paused | active",
  "budget_usdc": 150.0
}
```

**Response** (200 OK):
```json
{
  "campaign_id": "uuid",
  "status": "paused",
  "updated_at": "ISO8601"
}
```

---

## 2. Fleet Management

### 2.1 Get Fleet Status

**Endpoint**: `GET /fleet/status`

**Description**: Dashboard view of all agents (FR: OP-2)

**Query Parameters**:
- `tenant_id` (required): Filter by tenant

**Response** (200 OK):
```json
{
  "fleet_summary": {
    "total_agents": 15,
    "active_agents": 12,
    "idle_agents": 3
  },
  "agents": [
    {
      "agent_id": "uuid",
      "name": "FashionInfluencer_ET_001",
      "status": "planning | working | judging | sleeping | error",
      "current_task_id": "uuid | null",
      "wallet_balance_usdc": 45.67,
      "last_activity": "ISO8601"
    }
  ],
  "queue_depth": {
    "task_queue": 42,
    "review_queue": 7,
    "hitl_queue": 3
  },
  "financial_health": {
    "total_balance_usdc": 1234.56,
    "daily_spend_usdc": 89.12,
    "budget_utilization": 0.72
  }
}
```

---

### 2.2 Get Agent Details

**Endpoint**: `GET /agents/{agent_id}`

**Response** (200 OK):
```json
{
  "agent_id": "uuid",
  "name": "string",
  "soul_md_path": "personas/fashion_influencer_et.md",
  "wallet_address": "0x...",
  "tenant_id": "uuid",
  "status": "active",
  "persona": {
    "voice_traits": ["witty", "empathetic", "gen-z"],
    "core_beliefs": ["sustainability-focused"],
    "directives": ["never discuss politics"]
  },
  "memory_stats": {
    "short_term_items": 42,
    "long_term_vectors": 1523
  },
  "performance": {
    "total_tasks_completed": 234,
    "success_rate": 0.94,
    "avg_confidence_score": 0.87
  },
  "created_at": "ISO8601",
  "updated_at": "ISO8601"
}
```

---

## 3. Human-in-the-Loop (HITL) Review

### 3.1 Get HITL Queue

**Endpoint**: `GET /hitl/queue`

**Description**: Retrieve items escalated for human review (FR: REV-1)

**Query Parameters**:
- `tenant_id` (required)
- `status` (optional): `pending | approved | rejected`
- `page`, `limit`

**Response** (200 OK):
```json
{
  "items": [
    {
      "review_id": "uuid",
      "task_id": "uuid",
      "agent_id": "uuid",
      "task_type": "generate_content | reply_comment | execute_transaction",
      "content": {
        "text_content": "string",
        "media_urls": ["https://..."],
        "platform": "twitter"
      },
      "confidence_score": 0.75,
      "escalation_reason": "low_confidence | sensitive_topic | high_risk",
      "judge_reasoning": "string",
      "created_at": "ISO8601"
    }
  ],
  "pagination": { "page": 1, "limit": 20, "total": 7 }
}
```

---

### 3.2 Review Item

**Endpoint**: `POST /hitl/reviews/{review_id}/decision`

**Request**:
```json
{
  "decision": "approve | reject | edit",
  "edited_content": {
    "text_content": "string (optional, if decision=edit)",
    "media_urls": ["string"]
  },
  "reviewer_notes": "string (optional)"
}
```

**Response** (200 OK):
```json
{
  "review_id": "uuid",
  "decision": "approve",
  "task_status": "approved | rejected | requeued",
  "reviewed_by": "user_id",
  "reviewed_at": "ISO8601"
}
```

**Errors**:
- `404 Not Found`: Review item does not exist
- `409 Conflict`: Item already reviewed

---

## 4. Tasks & Swarm

### 4.1 Get Task Details

**Endpoint**: `GET /tasks/{task_id}`

**Response** (200 OK):
```json
{
  "task_id": "uuid",
  "task_type": "generate_content | reply_comment | fetch_trends | execute_transaction",
  "priority": "high | medium | low",
  "status": "pending | in_progress | review | complete | failed",
  "context": {
    "goal_description": "string",
    "persona_constraints": ["string"],
    "required_resources": ["mcp://twitter/mentions/123"]
  },
  "assigned_worker_id": "string | null",
  "result": {
    "status": "success | failure",
    "payload": {},
    "confidence_score": 0.92
  },
  "created_at": "ISO8601",
  "completed_at": "ISO8601 | null"
}
```

---

### 4.2 List Tasks

**Endpoint**: `GET /tasks`

**Query Parameters**:
- `campaign_id` (optional)
- `agent_id` (optional)
- `status` (optional)
- `page`, `limit`

**Response** (200 OK):
```json
{
  "tasks": [
    {
      "task_id": "uuid",
      "task_type": "generate_content",
      "status": "complete",
      "created_at": "ISO8601"
    }
  ],
  "pagination": { "page": 1, "limit": 50, "total": 234 }
}
```

---

## 5. Content Assets

### 5.1 Get Content Asset

**Endpoint**: `GET /content/{asset_id}`

**Response** (200 OK):
```json
{
  "id": "uuid",
  "agent_id": "uuid",
  "asset_type": "video | image | text",
  "external_id": "string (platform post ID)",
  "platform": "twitter | instagram | threads",
  "storage_url": "https://cdn.chimera.tech/...",
  "metadata": {
    "caption": "string",
    "hashtags": ["fashion", "ethiopia"],
    "engagement": {
      "likes": 234,
      "comments": 42,
      "shares": 18
    }
  },
  "video_metadata": {
    "duration_seconds": 45,
    "resolution": "1080p",
    "transcript_url": "https://...",
    "topics": ["fashion", "sustainability"],
    "relevance_score": 0.89,
    "processed_at": "ISO8601"
  },
  "created_at": "ISO8601"
}
```

---

### 5.2 List Content Assets

**Endpoint**: `GET /content`

**Query Parameters**:
- `agent_id` (optional)
- `asset_type` (optional)
- `platform` (optional)
- `page`, `limit`

**Response** (200 OK):
```json
{
  "assets": [
    {
      "id": "uuid",
      "asset_type": "image",
      "platform": "instagram",
      "storage_url": "https://...",
      "created_at": "ISO8601"
    }
  ],
  "pagination": { "page": 1, "limit": 20, "total": 156 }
}
```

---

## 6. Trends & Perception

### 6.1 Fetch Trends

**Endpoint**: `POST /trends/fetch`

**Description**: Trigger trend fetching for agent perception (FR: A-1)

**Request**:
```json
{
  "source_type": "news | social | market",
  "topic": "string (optional)",
  "limit": 10,
  "agent_id": "uuid (optional, for relevance filtering)"
}
```

**Response** (200 OK):
```json
{
  "trends": [
    {
      "source_id": "string",
      "source_type": "news",
      "title": "string",
      "summary": "string",
      "url": "https://...",
      "published_at": "ISO8601",
      "relevance_score": 0.85,
      "topics": ["fashion", "ethiopia"]
    }
  ],
  "fetched_at": "ISO8601"
}
```

---

## 7. Agentic Commerce

### 7.1 Get Wallet Balance

**Endpoint**: `GET /commerce/wallets/{agent_id}/balance`

**Response** (200 OK):
```json
{
  "agent_id": "uuid",
  "wallet_address": "0x...",
  "balances": {
    "eth": "0.0234",
    "usdc": "123.45"
  },
  "network": "base",
  "last_updated": "ISO8601"
}
```

---

### 7.2 Execute Transaction

**Endpoint**: `POST /commerce/transactions`

**Request**:
```json
{
  "agent_id": "uuid",
  "transaction_type": "native_transfer | deploy_token",
  "to_address": "0x...",
  "amount_usdc": 10.0,
  "purpose": "string (required for audit)"
}
```

**Response** (201 Created):
```json
{
  "transaction_id": "uuid",
  "status": "pending_cfo_review | approved | rejected | executed",
  "tx_hash": "0x... (if executed)",
  "created_at": "ISO8601"
}
```

**Errors**:
- `403 Forbidden`: Budget exceeded (CFO Judge rejection)
- `422 Unprocessable Entity`: Invalid address or amount

---

### 7.3 List Transactions

**Endpoint**: `GET /commerce/transactions`

**Query Parameters**:
- `agent_id` (optional)
- `status` (optional)
- `page`, `limit`

**Response** (200 OK):
```json
{
  "transactions": [
    {
      "transaction_id": "uuid",
      "agent_id": "uuid",
      "transaction_type": "native_transfer",
      "amount_usdc": 10.0,
      "status": "executed",
      "tx_hash": "0x...",
      "created_at": "ISO8601"
    }
  ],
  "pagination": { "page": 1, "limit": 50, "total": 89 }
}
```

---

## 8. Health & Monitoring

### 8.1 Health Check

**Endpoint**: `GET /health`

**Response** (200 OK):
```json
{
  "status": "healthy | degraded | unhealthy",
  "version": "0.1.0",
  "services": {
    "database": "healthy",
    "redis": "healthy",
    "weaviate": "healthy",
    "mcp_servers": {
      "twitter": "healthy",
      "weaviate": "healthy",
      "coinbase": "degraded"
    }
  },
  "timestamp": "ISO8601"
}
```

---

### 8.2 Metrics

**Endpoint**: `GET /metrics`

**Response** (200 OK):
```json
{
  "system": {
    "uptime_seconds": 123456,
    "active_workers": 12,
    "queue_depths": {
      "task_queue": 42,
      "review_queue": 7
    }
  },
  "performance": {
    "avg_task_duration_seconds": 12.34,
    "tasks_per_minute": 4.5,
    "error_rate": 0.02
  }
}
```

---

## Error Response Schema

All error responses follow this structure:

```json
{
  "error": {
    "code": "string (machine-readable)",
    "message": "string (human-readable)",
    "details": {
      "field": "validation error details (if applicable)"
    },
    "request_id": "uuid (for tracing)",
    "timestamp": "ISO8601"
  }
}
```

### Error Codes

| Code | HTTP Status | Description |
|------|-------------|-------------|
| `invalid_request` | 400 | Malformed request body or parameters |
| `unauthorized` | 401 | Missing or invalid authentication |
| `forbidden` | 403 | Insufficient permissions or quota exceeded |
| `not_found` | 404 | Resource does not exist |
| `conflict` | 409 | Resource state conflict (e.g., already reviewed) |
| `validation_error` | 422 | Request validation failed |
| `rate_limit_exceeded` | 429 | Too many requests |
| `internal_error` | 500 | Server error |
| `service_unavailable` | 503 | Temporary service disruption |

---

## Authentication

All endpoints (except `/health`) require authentication via **Bearer token**:

```
Authorization: Bearer <JWT_TOKEN>
```

JWT claims:
```json
{
  "sub": "user_id",
  "tenant_id": "uuid",
  "role": "operator | reviewer | admin",
  "exp": 1234567890
}
```

---

## Rate Limiting

- **Default**: 100 requests/minute per tenant
- **HITL endpoints**: 200 requests/minute
- **Commerce endpoints**: 10 requests/minute

Rate limit headers:
```
X-RateLimit-Limit: 100
X-RateLimit-Remaining: 87
X-RateLimit-Reset: 1234567890
```

---

## Versioning

API versioning via URL path: `/api/v1/...`

Breaking changes will increment the major version (v2, v3, etc.).
