# Security Policy

## Supported Versions

| Version | Supported          |
| ------- | ------------------ |
| 0.1.x   | :white_check_mark: |

## Reporting a Vulnerability

**DO NOT** open a public GitHub issue for security vulnerabilities.

### How to Report

1. **Email**: Send details to security@aiqem.tech
2. **Subject**: "SECURITY: [Brief description]"
3. **Include**:
   - Description of the vulnerability
   - Steps to reproduce
   - Potential impact
   - Suggested fix (if any)

### Response Timeline

- **Acknowledgment**: Within 24 hours
- **Initial Assessment**: Within 72 hours
- **Fix & Disclosure**: Within 30 days (for critical issues)

### What to Expect

1. **Acknowledgment**: We'll confirm receipt of your report
2. **Investigation**: We'll investigate and validate the issue
3. **Fix**: We'll develop and test a fix
4. **Disclosure**: We'll coordinate disclosure with you
5. **Credit**: We'll credit you in the security advisory (if desired)

---

## Security Architecture

See [ADR-005: Security Architecture](docs/adr/005-security-posture.md) for comprehensive security design.

### Key Security Measures

1. **Secrets Management**
   - Production: AWS Secrets Manager
   - Development: `.env` files (not committed)
   - Rotation: Every 90 days

2. **Authentication & Authorization**
   - JWT-based authentication
   - Role-based access control (RBAC)
   - Row-level security (RLS) in PostgreSQL

3. **Input Validation**
   - Pydantic models for API requests
   - Parameterized SQL queries (SQLAlchemy ORM)
   - XSS prevention (output encoding)

4. **Audit Logging**
   - All sensitive operations logged
   - Immutable audit trail
   - Retention: 1 year

5. **Network Security**
   - HTTPS only (TLS 1.3)
   - CORS whitelist
   - Rate limiting (100 req/min per tenant)

6. **Secret Scanning**
   - Gitleaks in CI/CD
   - Bandit (Python security linter)
   - Pre-commit hooks

---

## Security Best Practices for Contributors

### 1. Never Commit Secrets

**Forbidden**:
- API keys, tokens, passwords
- Private keys, certificates
- Database credentials
- `.env` files

**Use instead**:
- Environment variables
- AWS Secrets Manager (production)
- `.env.example` (template only)

### 2. Input Validation

**Always validate user input**:

```python
# GOOD: Pydantic validation
class CampaignCreate(BaseModel):
    goal_description: str = Field(..., min_length=10, max_length=500)
    budget_usdc: float = Field(..., gt=0, le=10000)

# BAD: No validation
def create_campaign(goal: str, budget: float):
    ...
```

### 3. SQL Injection Prevention

**Always use parameterized queries**:

```python
# GOOD: Parameterized query (SQLAlchemy)
agents = session.query(Agent).filter(Agent.tenant_id == tenant_id).all()

# BAD: String interpolation (SQL injection risk)
# agents = session.execute(f"SELECT * FROM agents WHERE tenant_id = '{tenant_id}'")
```

### 4. Authentication Required

**All API endpoints (except `/health`) require authentication**:

```python
from fastapi import Depends

@app.post("/campaigns")
async def create_campaign(
    campaign: CampaignCreate,
    user: dict = Depends(get_current_user)  # JWT verification
):
    ...
```

### 5. Multi-Tenancy Isolation

**Always filter by tenant_id**:

```python
# GOOD: Tenant-scoped query
campaigns = session.query(Campaign).filter(
    Campaign.tenant_id == user["tenant_id"]
).all()

# BAD: Global query (cross-tenant leak)
# campaigns = session.query(Campaign).all()
```

### 6. Audit Sensitive Operations

**Log all sensitive operations**:

```python
@audit_log(action="transfer_usdc", resource_type="transaction")
async def create_transaction(tx: TransactionCreate, user: dict):
    ...
```

---

## Security Checklist

Before submitting a PR, ensure:

- [ ] No hardcoded secrets (API keys, passwords, tokens)
- [ ] All user input validated (Pydantic models)
- [ ] SQL queries parameterized (no string interpolation)
- [ ] Authentication required for protected endpoints
- [ ] Tenant isolation enforced (filter by tenant_id)
- [ ] Sensitive operations logged to audit trail
- [ ] Dependencies up-to-date (no known vulnerabilities)
- [ ] `make security` passes (Bandit scan)
- [ ] Secret scanning passes (Gitleaks)

---

## Vulnerability Disclosure Policy

### Scope

**In scope**:
- Authentication bypass
- Authorization bypass (cross-tenant access)
- SQL injection
- XSS (Cross-Site Scripting)
- CSRF (Cross-Site Request Forgery)
- Secrets exposure
- API abuse (rate limiting bypass)
- Cryptographic weaknesses

**Out of scope**:
- Social engineering
- Physical attacks
- DDoS attacks
- Issues in third-party dependencies (report to upstream)
- Issues requiring physical access to servers

### Safe Harbor

We commit to:
- Not pursue legal action for good-faith security research
- Work with you to understand and resolve the issue
- Credit you in the security advisory (if desired)

We ask that you:
- Give us reasonable time to fix the issue before public disclosure
- Do not access or modify user data without permission
- Do not perform attacks that degrade service (DDoS, spam)

---

## Security Contacts

- **Email**: security@aiqem.tech
- **PGP Key**: [Available on request]
- **Response Time**: Within 24 hours

---

## Security Updates

Subscribe to security advisories:
- **GitHub**: Watch this repo for security advisories
- **Email**: security@aiqem.tech (request to be added to mailing list)

---

## Compliance

Project Chimera is designed to comply with:
- **GDPR** (General Data Protection Regulation)
- **AI Transparency Laws** (EU AI Act)
- **SOC 2** (Security, Availability, Confidentiality)

See [ADR-005](docs/adr/005-security-posture.md) for compliance details.

---

## Security Roadmap

### Phase 1 (Current)

- [x] Secrets management (AWS Secrets Manager)
- [x] JWT authentication
- [x] Row-level security (PostgreSQL RLS)
- [x] Input validation (Pydantic)
- [x] Audit logging
- [x] Secret scanning (CI/CD)

### Phase 2 (Q2 2026)

- [ ] Penetration testing
- [ ] Bug bounty program
- [ ] SOC 2 Type I certification
- [ ] Automated security testing (SAST, DAST)

### Phase 3 (Q3 2026)

- [ ] SOC 2 Type II certification
- [ ] ISO 27001 certification
- [ ] Advanced threat detection
- [ ] Security incident response plan (SIRP)

---

## References

- [ADR-005: Security Architecture](docs/adr/005-security-posture.md)
- [MCP Governance Rules](.cursor/rules/mcp-governance.mdc)
- [OWASP Top 10](https://owasp.org/www-project-top-ten/)
- [CWE Top 25](https://cwe.mitre.org/top25/)
