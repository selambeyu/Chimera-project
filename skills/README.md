# Chimera Agent Skills

**Definition**: A **Skill** is a specific capability package the Chimera Agent uses at runtime. Skills expose a stable Input/Output contract so the Planner and Workers can call them consistently. Skills may wrap MCP tools or custom logic.

**Rule**: All skill I/O MUST align with contracts in `specs/technical.md` (e.g. trend data structure, content metadata).

---

## Index of Skills

| Skill | Purpose | Input | Output |
|-------|---------|--------|--------|
| **skill_fetch_trends** | Fetch trend data (news, social, market) for the Planner. | `source_type`, `topic`, `limit` | List of trend items (see technical.md §1.3) |
| **skill_transcribe_audio** | Transcribe audio/video to text for indexing and reuse. | `audio_url` or `video_asset_id` | `transcript` text, `language`, `duration_seconds` |
| **skill_download_youtube** | Download video from YouTube for processing and repurposing. | `video_url`, `quality` | Local path or `storage_url`, `duration_seconds`, `metadata` |

---

## Contract Alignment

- **Trend data** returned by `skill_fetch_trends` MUST match the **Trend Data** schema in `specs/technical.md` (§1.3).
- **Content and video metadata** produced by skills SHOULD be storable in the **content_assets** / **video_metadata** schema in `specs/technical.md` (§2).

---

## Implementation Status

- **Structure only**: READMEs and I/O contracts are defined; full logic is not implemented yet.
- When implementing, check `specs/functional.md` (e.g. A-1, A-2) and `specs/technical.md` first.
