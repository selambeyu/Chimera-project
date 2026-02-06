# Skill: Download YouTube

**Purpose**: Download video from YouTube for processing, transcription, or repurposing. Used by the content pipeline before transcription or clipping.

---

## Input Contract

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `video_url` | `string` | Yes | YouTube URL (e.g. `https://www.youtube.com/watch?v=...`). |
| `quality` | `string` | No | Preferred quality: `high`, `medium`, `low`, or `audio_only`. Default: `medium`. |

**Example**:
```json
{
  "video_url": "https://www.youtube.com/watch?v=EXAMPLE",
  "quality": "medium"
}
```

---

## Output Contract

| Field | Type | Description |
|-------|------|-------------|
| `storage_url` | `string` | URL or path where the file is stored (e.g. S3, local path for dev). |
| `duration_seconds` | `float` | Duration of the video. |
| `metadata` | `object` | Optional: title, channel_id, resolution, format. |

**Example**:
```json
{
  "storage_url": "s3://bucket/chimera/downloads/EXAMPLE.mp4",
  "duration_seconds": 180.0,
  "metadata": {
    "title": "Video title",
    "resolution": "1280x720"
  }
}
```

- Output SHOULD be storable in **content_assets** and **video_metadata** in `specs/technical.md` (§2).
- On failure (invalid URL, download error): defined error response or exception; no partial file returned.

---

## Dependencies

- YouTube download capability (library or MCP tool); respect platform ToS and rate limits.
- Storage backend (e.g. S3, local) for `storage_url`; configuration via env.

---

## Implementation Note

Structure and contract only. When implementing, ensure alignment with `specs/technical.md` and content_assets schema.
