# Acceptance Criteria: Given/When/Then Scenarios

**Document**: Comprehensive acceptance criteria for all Project Chimera features
**Format**: Behavior-Driven Development (BDD) scenarios
**Last updated**: 2026-02-06

---

## 1. Campaign Management (OP-1, OP-2)

### Feature: Create Campaign Goal

**User Story**: OP-1 from `specs/functional.md`

#### Scenario 1.1: Successfully create campaign with valid goal

**Given**:
- Network Operator is authenticated with tenant_id `tenant-123`
- Operator has remaining campaign quota (< 10 active campaigns)
- Budget allocation is within tenant limits

**When**:
- Operator submits POST `/api/v1/campaigns` with:
  ```json
  {
    "goal_description": "Promote summer fashion in Ethiopia",
    "target_platforms": ["twitter", "instagram"],
    "priority": "high",
    "budget_usdc": 100.0,
    "start_date": "2026-02-10T00:00:00Z",
    "end_date": "2026-03-10T00:00:00Z",
    "tenant_id": "tenant-123"
  }
  ```

**Then**:
- Response status is `201 Created`
- Response body contains `campaign_id` (valid UUID)
- Response body contains `status: "planning"`
- Response body contains `task_tree_url`
- Campaign is stored in database with status `planning`
- Planner service receives campaign goal within 5 seconds
- Planner generates initial task tree within 30 seconds

**Measurable Thresholds**:
- API response time: < 500ms (p95)
- Task tree generation: < 30 seconds
- Campaign creation success rate: > 99%

---

#### Scenario 1.2: Reject campaign with invalid goal description

**Given**:
- Network Operator is authenticated

**When**:
- Operator submits POST `/api/v1/campaigns` with `goal_description` of 5 characters (< 10 char minimum)

**Then**:
- Response status is `422 Unprocessable Entity`
- Response body contains:
  ```json
  {
    "error": {
      "code": "validation_error",
      "message": "Validation failed",
      "details": {
        "goal_description": "Must be between 10 and 500 characters"
      }
    }
  }
  ```
- No campaign is created in database
- No task is sent to Planner

---

#### Scenario 1.3: Reject campaign when tenant quota exceeded

**Given**:
- Network Operator is authenticated with tenant_id `tenant-123`
- Tenant already has 10 active campaigns (quota limit)

**When**:
- Operator attempts to create 11th campaign

**Then**:
- Response status is `403 Forbidden`
- Response body contains:
  ```json
  {
    "error": {
      "code": "quota_exceeded",
      "message": "Campaign quota exceeded. Maximum 10 active campaigns per tenant.",
      "details": {
        "current_active": 10,
        "limit": 10
      }
    }
  }
  ```
- No campaign is created

---

### Feature: Monitor Fleet Status

**User Story**: OP-2 from `specs/functional.md`

#### Scenario 2.1: View fleet status dashboard

**Given**:
- Network Operator is authenticated with tenant_id `tenant-123`
- Tenant has 15 agents (12 active, 3 idle)
- Task queue has 42 pending tasks
- HITL queue has 3 escalated items

**When**:
- Operator requests GET `/api/v1/fleet/status?tenant_id=tenant-123`

**Then**:
- Response status is `200 OK`
- Response body contains:
  ```json
  {
    "fleet_summary": {
      "total_agents": 15,
      "active_agents": 12,
      "idle_agents": 3
    },
    "agents": [
      {
        "agent_id": "agent-001",
        "name": "FashionInfluencer_ET_001",
        "status": "working",
        "current_task_id": "task-456",
        "wallet_balance_usdc": 45.67,
        "last_activity": "2026-02-06T10:30:00Z"
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
- All agents belong to tenant-123 (no cross-tenant data leak)
- Response time < 1 second

**Measurable Thresholds**:
- API response time: < 1 second (p95)
- Data freshness: < 10 seconds old
- Cross-tenant isolation: 100% (zero leaks)

---

#### Scenario 2.2: Alert when budget utilization exceeds threshold

**Given**:
- Tenant has budget_limit of 1000 USDC
- Current daily_spend is 850 USDC (85% utilization)
- Alert threshold is 80%

**When**:
- Operator views fleet status

**Then**:
- Response includes alert:
  ```json
  {
    "alerts": [
      {
        "type": "budget_warning",
        "severity": "high",
        "message": "Daily spend at 85% of budget limit",
        "threshold": 0.80,
        "current": 0.85
      }
    ]
  }
  ```
- Alert is logged to monitoring system
- Notification is sent to operator (email/webhook)

---

## 2. Human-in-the-Loop Review (REV-1)

### Feature: Review Escalated Content

**User Story**: REV-1 from `specs/functional.md`

#### Scenario 3.1: Approve escalated content

**Given**:
- Human Reviewer is authenticated
- HITL queue contains review_id `review-789` with:
  - `confidence_score: 0.75` (below auto-approve threshold of 0.9)
  - `escalation_reason: "low_confidence"`
  - `status: "pending"`

**When**:
- Reviewer submits POST `/api/v1/hitl/reviews/review-789/decision` with:
  ```json
  {
    "decision": "approve",
    "reviewer_notes": "Content is appropriate and on-brand"
  }
  ```

**Then**:
- Response status is `200 OK`
- Review status updated to `approved`
- Associated task status updated to `complete`
- Content is published to target platform within 60 seconds
- Review is removed from HITL queue
- Reviewer action is logged with timestamp and user_id

**Measurable Thresholds**:
- Review decision processing: < 2 seconds
- Content publication after approval: < 60 seconds
- Audit log completeness: 100%

---

#### Scenario 3.2: Reject escalated content

**Given**:
- HITL queue contains review_id `review-790` with sensitive topic

**When**:
- Reviewer submits decision `reject` with notes "Content violates brand guidelines"

**Then**:
- Response status is `200 OK`
- Review status updated to `rejected`
- Associated task status updated to `failed`
- Content is NOT published
- Task is marked for Planner retry with rejection reason
- Rejection is logged for agent learning

---

#### Scenario 3.3: Edit and approve escalated content

**Given**:
- HITL queue contains review_id `review-791` with minor issues

**When**:
- Reviewer submits decision `edit` with:
  ```json
  {
    "decision": "edit",
    "edited_content": {
      "text_content": "Corrected caption with proper hashtags",
      "media_urls": ["https://cdn.chimera.tech/image-123.jpg"]
    },
    "reviewer_notes": "Fixed hashtag formatting"
  }
  ```

**Then**:
- Response status is `200 OK`
- Content is updated with edited version
- Edited content is published within 60 seconds
- Original and edited versions are both logged for audit
- Task is marked as `complete` with `human_edited: true` flag

---

#### Scenario 3.4: Prevent duplicate review

**Given**:
- Review_id `review-792` has already been reviewed and approved

**When**:
- Another reviewer attempts to review the same item

**Then**:
- Response status is `409 Conflict`
- Response body contains:
  ```json
  {
    "error": {
      "code": "already_reviewed",
      "message": "This item has already been reviewed",
      "details": {
        "reviewed_by": "user-456",
        "reviewed_at": "2026-02-06T10:15:00Z",
        "decision": "approve"
      }
    }
  }
  ```
- No changes are made to review or task

---

## 3. Agent Perception & Trend Fetching (A-1)

### Feature: Fetch Trend Data

**User Story**: A-1 from `specs/functional.md`

#### Scenario 4.1: Successfully fetch trends from news source

**Given**:
- Trend fetching skill is implemented
- News API is available and responsive
- Agent has valid API credentials

**When**:
- Planner calls `fetch_trends(source_type="news", topic="fashion", limit=10)`

**Then**:
- Function returns list of 10 trend items (or fewer if less available)
- Each item matches Trend Data schema from `specs/technical.md` §1.3:
  ```json
  {
    "source_id": "news-article-123",
    "source_type": "news",
    "title": "Sustainable Fashion Trends in East Africa",
    "summary": "...",
    "url": "https://newsapi.com/article/123",
    "published_at": "2026-02-06T08:00:00Z",
    "relevance_score": 0.87,
    "topics": ["fashion", "sustainability", "ethiopia"]
  }
  ```
- All relevance_scores are between 0.0 and 1.0
- All topics are non-empty lists of strings
- Function completes within 10 seconds

**Measurable Thresholds**:
- Fetch time: < 10 seconds (p95)
- Schema compliance: 100%
- Relevance score accuracy: > 80% (validated against manual review)

---

#### Scenario 4.2: Handle API timeout gracefully

**Given**:
- News API is slow or unresponsive (> 30 second timeout)

**When**:
- Planner calls `fetch_trends(source_type="news", topic="fashion", limit=10)`

**Then**:
- Function raises `TimeoutError` after 30 seconds
- Error message includes: "News API timeout after 30 seconds"
- No partial or corrupted data is returned
- Error is logged with timestamp, source_type, and topic
- Planner retries with exponential backoff (5s, 10s, 20s)

---

#### Scenario 4.3: Filter trends by relevance threshold

**Given**:
- Agent has active campaign with topics: ["fashion", "ethiopia"]
- Relevance threshold is set to 0.75

**When**:
- Trend fetcher returns 20 items with relevance_scores ranging from 0.5 to 0.95

**Then**:
- Semantic Filter passes only items with relevance_score >= 0.75
- Filtered list contains 8 items (all >= 0.75)
- Planner receives only high-relevance trends
- Low-relevance trends are logged but not processed

---

## 4. Content Generation (A-2)

### Feature: Generate Multimodal Content

**User Story**: A-2 from `specs/functional.md`

#### Scenario 5.1: Generate text content with persona consistency

**Given**:
- Agent `agent-001` has persona with voice_traits: ["witty", "empathetic", "gen-z"]
- Agent has active campaign: "Promote sustainable fashion"
- Worker receives task: `generate_content(type="text", context={...})`

**When**:
- Worker generates caption for Instagram post

**Then**:
- Generated text matches persona voice (witty, empathetic, Gen-Z tone)
- Text includes relevant hashtags (#SustainableFashion, #Ethiopia)
- Text length is appropriate for platform (< 2200 chars for Instagram)
- Judge validates text against persona constraints
- Confidence score is calculated (0.0-1.0)
- If confidence < 0.9, content is escalated to HITL

**Measurable Thresholds**:
- Generation time: < 5 seconds (p95)
- Persona consistency: > 90% (validated by Judge)
- Auto-approve rate (confidence >= 0.9): > 70%

---

#### Scenario 5.2: Generate image with character consistency

**Given**:
- Agent `agent-001` has character_reference_id: `char-ref-001`
- Worker receives task: `generate_content(type="image", context={...})`

**When**:
- Worker calls MCP Tool `generate_image` with character_reference_id

**Then**:
- Image generation request includes character_reference_id
- Generated image is validated by Judge using Vision API
- Judge compares generated image to reference image
- If similarity < 85%, image is rejected and regenerated
- If similarity >= 85%, image is approved
- Approved image is stored with metadata (resolution, storage_url)

**Measurable Thresholds**:
- Image generation time: < 30 seconds (p95)
- Character consistency: >= 85% similarity
- First-attempt success rate: > 80%

---

#### Scenario 5.3: Handle content generation failure

**Given**:
- Worker receives task: `generate_content(type="video", context={...})`
- Video generation API returns 500 Internal Server Error

**When**:
- Worker attempts to generate video

**Then**:
- Worker catches exception and logs error
- Worker returns result with `status: "failure"` and error details
- Judge receives failure result
- Judge signals Planner to retry task (max 3 retries)
- If all retries fail, task is escalated to HITL with error log
- No partial or corrupted content is published

---

## 5. Agentic Commerce (A-5)

### Feature: Execute On-Chain Transactions

**User Story**: A-5 from `specs/functional.md`

#### Scenario 6.1: Successfully transfer USDC within budget

**Given**:
- Agent `agent-001` has wallet with balance: 100 USDC
- Daily budget limit: 50 USDC
- Current daily spend: 20 USDC
- Worker proposes transaction: transfer 10 USDC to designer wallet

**When**:
- Worker submits transaction request to CFO Judge

**Then**:
- CFO Judge checks balance: 100 USDC (sufficient)
- CFO Judge checks daily budget: 20 + 10 = 30 USDC (< 50 limit)
- CFO Judge approves transaction
- Transaction is executed via Coinbase AgentKit
- Transaction hash is returned and logged
- Daily spend is updated to 30 USDC in Redis
- Transaction record is stored in database

**Measurable Thresholds**:
- Budget check time: < 1 second
- Transaction execution time: < 30 seconds (on-chain confirmation)
- Budget tracking accuracy: 100%

---

#### Scenario 6.2: Reject transaction exceeding daily budget

**Given**:
- Agent `agent-001` has wallet with balance: 100 USDC
- Daily budget limit: 50 USDC
- Current daily spend: 45 USDC
- Worker proposes transaction: transfer 10 USDC (would exceed limit)

**When**:
- Worker submits transaction request to CFO Judge

**Then**:
- CFO Judge checks daily budget: 45 + 10 = 55 USDC (> 50 limit)
- CFO Judge rejects transaction with reason: "Budget exceeded"
- Response status is `403 Forbidden`
- Response body contains:
  ```json
  {
    "error": {
      "code": "budget_exceeded",
      "message": "Daily budget limit exceeded",
      "details": {
        "daily_limit_usdc": 50.0,
        "current_spend_usdc": 45.0,
        "requested_amount_usdc": 10.0,
        "would_exceed_by_usdc": 5.0
      }
    }
  }
  ```
- Transaction is NOT executed
- Task is flagged for human review
- No funds are transferred

---

#### Scenario 6.3: Reject transaction with insufficient balance

**Given**:
- Agent `agent-001` has wallet with balance: 5 USDC
- Worker proposes transaction: transfer 10 USDC

**When**:
- Worker submits transaction request

**Then**:
- CFO Judge checks balance: 5 USDC (< 10 USDC requested)
- CFO Judge rejects transaction with reason: "Insufficient balance"
- Response status is `422 Unprocessable Entity`
- Transaction is NOT executed
- Alert is sent to operator: "Agent wallet balance low"

---

#### Scenario 6.4: Detect and block suspicious transaction

**Given**:
- Agent `agent-001` typically transfers 5-20 USDC per transaction
- Worker proposes transaction: transfer 500 USDC (anomaly)

**When**:
- Worker submits transaction request to CFO Judge

**Then**:
- CFO Judge detects anomaly (10x typical amount)
- CFO Judge flags transaction as suspicious
- Transaction is NOT auto-approved
- Transaction is escalated to HITL with:
  ```json
  {
    "escalation_reason": "anomalous_transaction",
    "details": {
      "requested_amount_usdc": 500.0,
      "typical_amount_usdc": 12.5,
      "anomaly_factor": 40.0
    }
  }
  ```
- Human reviewer must approve before execution
- Agent is temporarily paused for security review

---

## 6. Edge Cases & Failure Modes

### Scenario 7.1: Handle database connection loss

**Given**:
- API server is running
- PostgreSQL database becomes unavailable (network partition)

**When**:
- Client requests GET `/api/v1/campaigns`

**Then**:
- API attempts database query
- Query times out after 5 seconds
- Response status is `503 Service Unavailable`
- Response body contains:
  ```json
  {
    "error": {
      "code": "service_unavailable",
      "message": "Database temporarily unavailable. Please retry.",
      "retry_after_seconds": 30
    }
  }
  ```
- Error is logged with severity: CRITICAL
- Health check endpoint reports `status: "unhealthy"`
- No data corruption occurs

---

### Scenario 7.2: Handle Redis queue failure

**Given**:
- Planner is generating tasks
- Redis (task queue) becomes unavailable

**When**:
- Planner attempts to push task to queue

**Then**:
- Planner catches Redis connection error
- Planner falls back to database-backed queue (slower but reliable)
- Task is stored in PostgreSQL `tasks` table with `status: "queued"`
- Alert is sent to ops team: "Redis unavailable, using fallback queue"
- Workers poll database queue instead of Redis
- System continues operating (degraded performance)

---

### Scenario 7.3: Handle MCP server unavailability

**Given**:
- Worker needs to call MCP Tool `generate_image`
- MCP server `mcp-server-ideogram` is down

**When**:
- Worker attempts to call tool

**Then**:
- MCP client detects server unavailability
- Worker retries with exponential backoff (3 attempts)
- If all retries fail, Worker returns failure result
- Judge escalates task to HITL with error: "Image generation service unavailable"
- Health check endpoint reports degraded MCP service
- System continues with other tasks

---

### Scenario 7.4: Handle concurrent state updates (OCC)

**Given**:
- Judge A is reviewing task-001 (state_version: 42)
- Judge B is reviewing task-002 (state_version: 42)
- Both judges attempt to commit results simultaneously

**When**:
- Judge A commits first (state_version updates to 43)
- Judge B attempts to commit (expects state_version 42, but finds 43)

**Then**:
- Judge B's commit fails (state version mismatch)
- Judge B detects OCC conflict
- Judge B re-fetches current state (version 43)
- Judge B re-validates result against new state
- If still valid, Judge B retries commit (state_version 43 → 44)
- If invalid (e.g., campaign paused), Judge B discards result

---

## 7. Performance & Scalability

### Scenario 8.1: Handle burst traffic

**Given**:
- System normally handles 100 requests/minute
- Viral event causes 1000 requests/minute spike

**When**:
- Traffic increases 10x

**Then**:
- API auto-scales horizontally (Kubernetes HPA)
- New pods spin up within 60 seconds
- Rate limiting protects backend (429 responses for excess traffic)
- Priority queue ensures critical operations (HITL, commerce) are processed first
- Non-critical operations (analytics) are delayed
- System maintains < 5 second p95 response time for critical endpoints
- No data loss or corruption occurs

**Measurable Thresholds**:
- Auto-scale response time: < 60 seconds
- Critical endpoint p95 latency: < 5 seconds (under load)
- Data integrity: 100% (no lost requests)

---

### Scenario 8.2: Handle large campaign with 1000+ tasks

**Given**:
- Operator creates campaign with complex goal
- Planner generates 1000 tasks

**When**:
- Planner pushes 1000 tasks to queue

**Then**:
- Tasks are batched (100 tasks per batch)
- Queue ingestion completes within 10 seconds
- Workers process tasks in parallel (10-50 concurrent workers)
- All 1000 tasks complete within 2 hours (average 7.2 seconds per task)
- Progress is updated in real-time (every 10 seconds)
- Operator can view progress via dashboard

**Measurable Thresholds**:
- Queue ingestion: < 10 seconds for 1000 tasks
- Task completion: < 2 hours for 1000 tasks
- Worker concurrency: 10-50 workers
- Progress update frequency: every 10 seconds

---

## 8. Security & Compliance

### Scenario 9.1: Prevent cross-tenant data access

**Given**:
- User A belongs to tenant-123
- User B belongs to tenant-456
- Campaign `camp-789` belongs to tenant-123

**When**:
- User B (tenant-456) requests GET `/api/v1/campaigns/camp-789`

**Then**:
- API validates JWT token (tenant_id: tenant-456)
- API checks campaign ownership (tenant_id: tenant-123)
- Tenant mismatch detected
- Response status is `403 Forbidden`
- Response body contains:
  ```json
  {
    "error": {
      "code": "forbidden",
      "message": "Access denied. Resource belongs to different tenant."
    }
  }
  ```
- Access attempt is logged for security audit
- No campaign data is returned

**Measurable Thresholds**:
- Cross-tenant isolation: 100% (zero leaks)
- Authorization check time: < 50ms
- Security audit log completeness: 100%

---

### Scenario 9.2: Validate and sanitize user input

**Given**:
- Attacker attempts SQL injection via goal_description

**When**:
- Attacker submits POST `/api/v1/campaigns` with:
  ```json
  {
    "goal_description": "Test'; DROP TABLE campaigns; --"
  }
  ```

**Then**:
- API validates input using parameterized queries (SQLAlchemy ORM)
- Input is treated as literal string, not SQL code
- Campaign is created with goal_description: "Test'; DROP TABLE campaigns; --"
- No SQL injection occurs
- Database tables remain intact
- Suspicious input is logged for security review

---

### Scenario 9.3: Enforce rate limiting

**Given**:
- Tenant has rate limit: 100 requests/minute
- Tenant has made 100 requests in the last 60 seconds

**When**:
- Tenant makes 101st request within the same minute

**Then**:
- Response status is `429 Too Many Requests`
- Response headers include:
  ```
  X-RateLimit-Limit: 100
  X-RateLimit-Remaining: 0
  X-RateLimit-Reset: 1234567890
  Retry-After: 30
  ```
- Response body contains:
  ```json
  {
    "error": {
      "code": "rate_limit_exceeded",
      "message": "Rate limit exceeded. Please retry after 30 seconds.",
      "retry_after_seconds": 30
    }
  }
  ```
- Request is not processed
- Rate limit violation is logged

---

## Summary

This document defines **measurable acceptance criteria** for all major features in Project Chimera. Each scenario includes:

- **Given**: Preconditions and system state
- **When**: Action or trigger
- **Then**: Expected outcomes and side effects
- **Measurable Thresholds**: Quantitative success criteria

These scenarios serve as:
1. **Acceptance tests** for feature completion
2. **Regression tests** to prevent breakage
3. **Performance benchmarks** for optimization
4. **Security validation** for compliance

All scenarios link back to:
- **User Stories**: `specs/functional.md`
- **API Contracts**: `specs/technical.md`, `specs/api_endpoints.md`
- **Data Schemas**: `specs/technical.md` §2 (Database Schema)
