# ADR-005: Security Architecture and Secrets Management

## Status

**Accepted** - 2026-02-06

## Context

Project Chimera handles sensitive data and operations:
- **Financial transactions**: Crypto wallet operations (USDC transfers)
- **API credentials**: Twitter, Instagram, news APIs, image generation
- **User data**: Campaign goals, content, analytics
- **Multi-tenancy**: Strict isolation between tenants

Security requirements:
- **Secrets management**: Secure storage and rotation of API keys, tokens, private keys
- **Authentication**: Verify user identity
- **Authorization**: Enforce tenant-based access control
- **Input validation**: Prevent injection attacks
- **Audit logging**: Track all sensitive operations
- **Compliance**: GDPR, AI transparency laws

### Security Approaches

1. **Basic**: Environment variables, no encryption
2. **Intermediate**: Secrets manager (AWS Secrets Manager, HashiCorp Vault)
3. **Advanced**: Hardware Security Modules (HSMs), zero-trust architecture

## Decision

We will implement a **layered security architecture** with:
1. **Secrets Manager** (AWS Secrets Manager) for production
2. **JWT-based authentication** with role-based access control (RBAC)
3. **Row-level security** (RLS) in PostgreSQL for multi-tenancy
4. **Input validation** at API layer (Pydantic models)
5. **Audit logging** for all sensitive operations
6. **Secret scanning** in CI/CD pipeline

## Rationale

**Layered security**:
- **Defense in depth**: Multiple layers prevent single point of failure
- **Compliance**: Meets GDPR, SOC 2, AI transparency requirements
- **Scalability**: Secrets manager scales to thousands of secrets
- **Auditability**: Comprehensive logs for compliance and forensics

**Secrets Manager advantages**:
- **Encryption at rest**: AES-256 encryption
- **Automatic rotation**: Rotate secrets without downtime
- **Access control**: IAM policies control who can access secrets
- **Audit trail**: CloudTrail logs all secret access
- **Cost-effective**: $0.40/secret/month + $0.05/10K API calls

**JWT authentication**:
- **Stateless**: No session storage required
- **Scalable**: Works across multiple API servers
- **Standard**: Industry-standard protocol (RFC 7519)
- **Flexible**: Supports custom claims (tenant_id, role)

## Consequences

### Positive

- **Secure secrets**: No hardcoded credentials, encrypted at rest
- **Automatic rotation**: Secrets rotated every 90 days without manual intervention
- **Multi-tenancy**: Row-level security prevents cross-tenant data access
- **Audit trail**: All sensitive operations logged for compliance
- **Compliance**: Meets GDPR, SOC 2, AI transparency requirements

### Negative

- **Complexity**: Additional infrastructure (Secrets Manager, JWT service)
- **Cost**: $50-100/month for Secrets Manager (production)
- **Latency**: Secret retrieval adds ~50ms (mitigated by caching)

### Mitigations

1. **Development**: Use `.env` files for local development (not committed)
2. **Caching**: Cache secrets in memory (refresh every 1 hour)
3. **Fallback**: Graceful degradation if Secrets Manager unavailable

## Implementation

### 1. Secrets Management

**Production**: AWS Secrets Manager

```python
import boto3
from botocore.exceptions import ClientError

def get_secret(secret_name: str) -> dict:
    """Retrieve secret from AWS Secrets Manager."""
    client = boto3.client('secretsmanager', region_name='us-east-1')
    try:
        response = client.get_secret_value(SecretId=secret_name)
        return json.loads(response['SecretString'])
    except ClientError as e:
        logger.error(f"Failed to retrieve secret {secret_name}: {e}")
        raise
```

**Development**: `.env` file (not committed)

```bash
# .env (local development only)
DATABASE_PASSWORD=local_dev_password
TWITTER_API_KEY=test_key
CDP_API_KEY_PRIVATE_KEY=test_private_key
```

**Secrets Rotation**: Automatic every 90 days via Lambda function

---

### 2. Authentication & Authorization

**JWT Token Structure**:

```json
{
  "sub": "user-123",
  "tenant_id": "tenant-456",
  "role": "operator",
  "exp": 1234567890
}
```

**API Authentication**:

```python
from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
import jwt

security = HTTPBearer()

async def get_current_user(credentials: HTTPAuthorizationCredentials = Depends(security)):
    """Verify JWT token and extract user info."""
    try:
        payload = jwt.decode(
            credentials.credentials,
            SECRET_KEY,
            algorithms=["HS256"]
        )
        return {
            "user_id": payload["sub"],
            "tenant_id": payload["tenant_id"],
            "role": payload["role"]
        }
    except jwt.ExpiredSignatureError:
        raise HTTPException(status_code=401, detail="Token expired")
    except jwt.InvalidTokenError:
        raise HTTPException(status_code=401, detail="Invalid token")
```

**Authorization Decorator**:

```python
def require_role(required_role: str):
    """Decorator to enforce role-based access control."""
    def decorator(func):
        async def wrapper(*args, user=Depends(get_current_user), **kwargs):
            if user["role"] != required_role:
                raise HTTPException(status_code=403, detail="Insufficient permissions")
            return await func(*args, user=user, **kwargs)
        return wrapper
    return decorator

@app.post("/campaigns")
@require_role("operator")
async def create_campaign(campaign: CampaignCreate, user: dict):
    # Only operators can create campaigns
    ...
```

---

### 3. Multi-Tenancy (Row-Level Security)

**PostgreSQL RLS Policy**:

```sql
-- Enable RLS on agents table
ALTER TABLE agents ENABLE ROW LEVEL SECURITY;

-- Policy: Users can only see agents from their tenant
CREATE POLICY tenant_isolation ON agents
    FOR ALL
    USING (tenant_id = current_setting('app.current_tenant_id')::uuid);

-- Set tenant context for each request
SET app.current_tenant_id = 'tenant-123';
```

**SQLAlchemy Implementation**:

```python
from sqlalchemy import event
from sqlalchemy.orm import Session

@event.listens_for(Session, "after_begin")
def set_tenant_context(session, transaction, connection):
    """Set tenant context for RLS."""
    tenant_id = get_current_tenant_id()  # From JWT token
    connection.execute(f"SET app.current_tenant_id = '{tenant_id}'")
```

---

### 4. Input Validation

**Pydantic Models**:

```python
from pydantic import BaseModel, Field, validator

class CampaignCreate(BaseModel):
    goal_description: str = Field(..., min_length=10, max_length=500)
    budget_usdc: float = Field(..., gt=0, le=10000)
    tenant_id: str = Field(..., regex=r'^[a-f0-9-]{36}$')  # UUID format
    
    @validator('goal_description')
    def sanitize_goal(cls, v):
        """Remove potentially malicious characters."""
        return v.strip()
```

**SQL Injection Prevention**:

```python
# GOOD: Parameterized query (SQLAlchemy ORM)
agents = session.query(Agent).filter(Agent.tenant_id == tenant_id).all()

# BAD: String interpolation (vulnerable to SQL injection)
# agents = session.execute(f"SELECT * FROM agents WHERE tenant_id = '{tenant_id}'")
```

---

### 5. Audit Logging

**Audit Log Schema**:

```sql
CREATE TABLE audit_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    timestamp TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    user_id UUID NOT NULL,
    tenant_id UUID NOT NULL,
    action VARCHAR(100) NOT NULL,  -- 'create_campaign', 'approve_content', 'transfer_usdc'
    resource_type VARCHAR(50) NOT NULL,  -- 'campaign', 'content', 'transaction'
    resource_id UUID,
    details JSONB,
    ip_address INET,
    user_agent TEXT
);

-- Index for fast queries
CREATE INDEX idx_audit_logs_tenant_timestamp ON audit_logs(tenant_id, timestamp DESC);
CREATE INDEX idx_audit_logs_user_action ON audit_logs(user_id, action);
```

**Audit Logging Decorator**:

```python
from functools import wraps

def audit_log(action: str, resource_type: str):
    """Decorator to automatically log sensitive operations."""
    def decorator(func):
        @wraps(func)
        async def wrapper(*args, user: dict, **kwargs):
            result = await func(*args, user=user, **kwargs)
            
            # Log to audit_logs table
            await log_audit_event(
                user_id=user["user_id"],
                tenant_id=user["tenant_id"],
                action=action,
                resource_type=resource_type,
                resource_id=result.get("id"),
                details={"args": args, "kwargs": kwargs}
            )
            
            return result
        return wrapper
    return decorator

@app.post("/commerce/transactions")
@audit_log(action="transfer_usdc", resource_type="transaction")
async def create_transaction(tx: TransactionCreate, user: dict):
    ...
```

---

### 6. Secret Scanning (CI/CD)

**GitHub Actions Workflow**:

```yaml
name: Security Scan

on: [push, pull_request]

jobs:
  secret-scan:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0  # Full history for secret scanning
      
      - name: Run Gitleaks (secret scanner)
        uses: gitleaks/gitleaks-action@v2
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
      
      - name: Run Bandit (Python security linter)
        run: |
          pip install bandit
          bandit -r src/ skills/ -c pyproject.toml
```

**.gitleaks.toml** (secret patterns):

```toml
[[rules]]
id = "github-pat"
description = "GitHub Personal Access Token"
regex = '''ghp_[0-9a-zA-Z]{36}'''

[[rules]]
id = "aws-access-key"
description = "AWS Access Key"
regex = '''AKIA[0-9A-Z]{16}'''

[[rules]]
id = "private-key"
description = "Private Key"
regex = '''-----BEGIN (RSA|EC|OPENSSH) PRIVATE KEY-----'''
```

---

## Security Checklist

- [ ] All secrets stored in AWS Secrets Manager (production)
- [ ] No hardcoded credentials in code or config files
- [ ] JWT authentication on all API endpoints (except `/health`)
- [ ] Row-level security (RLS) enabled on all multi-tenant tables
- [ ] Input validation using Pydantic models
- [ ] SQL injection prevention (parameterized queries)
- [ ] Audit logging for all sensitive operations
- [ ] Secret scanning in CI/CD pipeline (Gitleaks, Bandit)
- [ ] HTTPS only (no HTTP in production)
- [ ] Rate limiting on all API endpoints
- [ ] CORS configured (whitelist only)
- [ ] Security headers (CSP, X-Frame-Options, etc.)

---

## Alternatives Considered

### Environment Variables Only

**Pros**: Simple, no additional infrastructure
**Cons**: No encryption, no rotation, secrets in plaintext
**Verdict**: Not secure for production

### HashiCorp Vault

**Pros**: More features than AWS Secrets Manager, open-source
**Cons**: Requires self-hosting, more complex setup
**Verdict**: Overkill for early stage; AWS Secrets Manager is sufficient

### Hardware Security Modules (HSMs)

**Pros**: Highest security (FIPS 140-2 Level 3)
**Cons**: Very expensive ($1000+/month), complex integration
**Verdict**: Not needed for current scale

---

## References

- AWS Secrets Manager: https://aws.amazon.com/secrets-manager/
- JWT Specification: https://datatracker.ietf.org/doc/html/rfc7519
- PostgreSQL RLS: https://www.postgresql.org/docs/current/ddl-rowsecurity.html
- OWASP Top 10: https://owasp.org/www-project-top-ten/
- `SECURITY.md` - Security policy and reporting
- `.cursor/rules/mcp-governance.mdc` - MCP security rules
