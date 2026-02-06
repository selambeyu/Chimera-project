"""
Transcribe audio: contract in skills/skill_transcribe_audio/README.md.
Implement this so test_skills_interface.py passes.
"""


def transcribe_audio(
    audio_url: str | None = None,
    video_asset_id: str | None = None,
) -> dict:
    """
    Transcribe audio or video. Exactly one of audio_url or video_asset_id required.
    Returns dict with transcript, language, duration_seconds.
    """
    raise NotImplementedError(
        "Transcribe skill not implemented. Contract: skills/skill_transcribe_audio/README.md"
    )
