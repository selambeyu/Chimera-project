"""
TDD: Asserts that skills/ modules accept the correct parameters per their contracts.
Contract: skills/*/README.md and specs/technical.md.
These tests SHOULD fail until each skill is implemented (NotImplementedError).
"""

import pytest

from skills.skill_fetch_trends.fetch import fetch_trends
from skills.skill_transcribe_audio.transcribe import transcribe_audio
from skills.skill_download_youtube.download import download_youtube


def test_fetch_trends_accepts_contract_params() -> None:
    """skill_fetch_trends must accept source_type, optional topic, limit."""
    # Call with correct params; fails with NotImplementedError until implemented
    result = fetch_trends(source_type="news", topic="fashion", limit=5)
    assert result is not None  # when implemented, returns list


def test_transcribe_audio_accepts_contract_params() -> None:
    """skill_transcribe_audio must accept audio_url OR video_asset_id."""
    # Call with audio_url; fails with NotImplementedError until implemented
    result = transcribe_audio(audio_url="https://example.com/audio.mp3")
    assert result is not None
    assert "transcript" in result
    assert "language" in result
    assert "duration_seconds" in result


def test_transcribe_audio_accepts_video_asset_id() -> None:
    """skill_transcribe_audio must accept video_asset_id as alternative input."""
    result = transcribe_audio(video_asset_id="test-uuid-asset")
    assert result is not None
    assert "transcript" in result


def test_download_youtube_accepts_contract_params() -> None:
    """skill_download_youtube must accept video_url, optional quality."""
    result = download_youtube(
        video_url="https://www.youtube.com/watch?v=EXAMPLE",
        quality="medium",
    )
    assert result is not None
    assert "storage_url" in result
    assert "duration_seconds" in result
    assert "metadata" in result
