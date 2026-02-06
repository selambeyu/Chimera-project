# Skill: Fetch Trends

**Purpose**: Fetch trend data (news, social, or market) so the Planner can decide what content to create. Aligns with user story **A-1** in `specs/functional.md`.

---

## Input Contract

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `source_type` | `string` | Yes | One of: `news`, `social`, `market`. |
| `topic` | `string` | No | Optional filter (e.g. "fashion", "ethiopia"). |
| `limit` | `int` | No | Max items to return (default: 10). |

**Example**:
```json
{
  "source_type": "news",
  "topic": "fashion",
  "limit": 5
}
```

---

## Output Contract

Returns a **list** of trend items. Each item MUST conform to the **Trend Data** schema in `specs/technical.md` (§1.3):

```json
[
  {
    "source_id": "string",
    "source_type": "news",
    "title": "string",
    "summary": "string",
    "url": "string",
    "published_at": "ISO8601",
    "relevance_score": 0.0,
    "topics": ["string"]
  }
]
```

- `relevance_score`: Float in [0.0, 1.0]; used by Planner for filtering.
- Empty result: return `[]`.

---

## Dependencies

- MCP Resource(s) or external API for news/social/market (e.g. `news://latest`, or a configured trend API).
- No runtime secrets required for read-only trend fetch; API keys if needed via env.

---

## Implementation Note

Full logic not implemented yet. When implementing, use `specs/technical.md` and ensure all consumers (Planner, tests) use this contract.
