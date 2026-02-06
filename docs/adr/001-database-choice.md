# ADR-001: PostgreSQL as Primary Database

## Status

**Accepted** - 2026-02-06

## Context

Project Chimera requires a robust database solution for storing:
- Agent metadata (personas, wallets, tenant associations)
- Campaign configurations and goals
- Task execution history and audit logs
- Content assets and video metadata
- Transactional data with ACID guarantees

We evaluated three options:
1. **PostgreSQL** - Relational database with JSONB support
2. **MongoDB** - Document database with flexible schema
3. **DynamoDB** - Managed NoSQL database (AWS)

### Requirements

- **ACID transactions** for financial operations (wallet balances, transactions)
- **Multi-tenancy** with strict data isolation
- **Complex queries** (JOINs across agents, campaigns, tasks, content)
- **JSON storage** for flexible metadata (task context, content metadata)
- **Vector search** capability (or integration with vector DB)
- **Audit logging** with immutable history
- **Cost-effective** for early-stage startup

## Decision

We will use **PostgreSQL 16** as the primary transactional database.

### Rationale

**PostgreSQL strengths**:
1. **ACID compliance**: Critical for financial transactions (Coinbase wallet operations)
2. **JSONB support**: Flexible metadata storage without sacrificing query performance
3. **Row-level security**: Native multi-tenancy via tenant_id filtering
4. **pgvector extension**: Vector similarity search for semantic queries (alternative to Weaviate for some use cases)
5. **Mature ecosystem**: Well-supported ORMs (SQLAlchemy), migration tools (Alembic), monitoring
6. **Open source**: No vendor lock-in, can self-host or use managed services (RDS, Supabase)
7. **Performance**: Handles 10K+ transactions/second with proper indexing
8. **Cost**: Free for self-hosted, $20-50/month for managed (vs $100+ for DynamoDB at scale)

**MongoDB drawbacks**:
- Weaker transaction guarantees (multi-document transactions added only recently)
- JOIN operations are expensive (aggregation pipeline)
- Less mature for financial applications

**DynamoDB drawbacks**:
- Vendor lock-in (AWS-only)
- Complex pricing model (read/write capacity units)
- Limited query flexibility (requires careful index design)
- No native JOIN support

## Consequences

### Positive

- **Data integrity**: ACID transactions ensure wallet balance consistency
- **Query flexibility**: Complex analytics queries across multiple tables
- **Multi-tenancy**: Row-level security policies enforce tenant isolation
- **Audit trail**: Immutable logs via append-only tables and triggers
- **Developer experience**: Familiar SQL, excellent tooling (pgAdmin, DBeaver)
- **Cost predictability**: Fixed monthly cost for managed Postgres

### Negative

- **Scaling complexity**: Horizontal scaling requires sharding or read replicas
- **Schema migrations**: Require careful planning and downtime (mitigated by Alembic)
- **Vector search**: pgvector is less mature than Weaviate for large-scale semantic search

### Mitigations

1. **Scaling**: Use read replicas for analytics queries, connection pooling (PgBouncer)
2. **Migrations**: Blue-green deployments, backward-compatible schema changes
3. **Vector search**: Use Weaviate for primary semantic memory, Postgres for transactional data

## Implementation

### Database Schema

See `specs/technical.md` §2 for complete ERD.

Key tables:
- `agents` - Agent registry
- `campaigns` - Campaign goals and status
- `tasks` - Task execution history
- `content_assets` - Published content
- `video_metadata` - Video-specific metadata
- `transactions` - Financial transaction log

### Connection String

```
postgresql://chimera:{password}@{host}:5432/chimera?sslmode=require
```

### ORM

SQLAlchemy 2.0 with async support (asyncpg driver)

### Migrations

Alembic for schema versioning and migrations

### Backup Strategy

- **Daily backups**: Full database backup to S3
- **Point-in-time recovery**: WAL archiving (last 7 days)
- **Replication**: Streaming replication to standby (production)

## Alternatives Considered

### MongoDB

**Pros**: Flexible schema, horizontal scaling
**Cons**: Weaker transactions, expensive JOINs
**Verdict**: Not suitable for financial data

### DynamoDB

**Pros**: Fully managed, auto-scaling
**Cons**: Vendor lock-in, complex pricing, limited queries
**Verdict**: Too expensive and inflexible for early stage

### MySQL

**Pros**: Similar to Postgres, widely used
**Cons**: Weaker JSON support, less advanced features
**Verdict**: Postgres is superior for our use case

## References

- PostgreSQL Documentation: https://www.postgresql.org/docs/16/
- SQLAlchemy: https://docs.sqlalchemy.org/
- Alembic: https://alembic.sqlalchemy.org/
- `specs/technical.md` §2 - Database Schema
- `specs/mcp_servers.md` §3.1 - mcp-server-postgres
