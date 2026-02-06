# Skill: Transcribe Audio

**Purpose**: Transcribe audio or video to text for indexing, search, and content reuse. Supports trend and content pipelines.

---

## Input Contract

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `audio_url` | `string` | One of | URL of audio file (e.g. S3, public URL). |
| `video_asset_id` | `string` | One of | ID of a content_asset (video) already stored; skill resolves URL from asset. |

**Example (URL)**:
```json
{
  "audio_url": "https://example.com/audio.mp3"
}
```

**Example (asset)**:
```json
{
  "video_asset_id": "uuid-of-content-asset"
}
```

---

## Output Contract

| Field | Type | Description |
|-------|------|-------------|
| `transcript` | `string` | Full text of the transcription. |
| `language` | `string` | ISO 639-1 (e.g. `en`, `am`). |
| `duration_seconds` | `float` | Duration of the source audio/video. |

**Example**:
```json
{
  "transcript": "Full text here...",
  "language": "en",
  "duration_seconds": 120.5
}
```

- On failure (e.g. unsupported format, fetch error): skill returns an error payload or raises a defined exception; contract may be extended with `error_code` and `message`.

---

## Dependencies

- Transcription service (e.g. MCP tool, Whisper API, or third-party). Not specified here.
- If using `video_asset_id`, access to content_assets storage or API.

---

## Implementation Note

Structure and contract only. When implementing, align with `specs/technical.md` (e.g. video_metadata.transcript_url, duration_seconds).
