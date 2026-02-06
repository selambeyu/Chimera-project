"""
Download YouTube video: contract in skills/skill_download_youtube/README.md.
Implement this so test_skills_interface.py passes.
"""


def download_youtube(
    video_url: str,
    quality: str = "medium",
) -> dict:
    """
    Download video from YouTube. quality: high, medium, low, or audio_only.
    Returns dict with storage_url, duration_seconds, metadata.
    """
    raise NotImplementedError(
        "Download YouTube skill not implemented. Contract: skills/skill_download_youtube/README.md"
    )
