"""
Trend fetcher: contract in specs/technical.md §1.3 and skills/skill_fetch_trends/README.md.
Implement this so test_trend_fetcher.py passes.
"""


def fetch_trends(
    source_type: str,
    topic: str | None = None,
    limit: int = 10,
) -> list[dict]:
    """
    Fetch trend data. Returns list of items matching Trend Data schema.
    source_type: one of 'news', 'social', 'market'.
    """
    raise NotImplementedError(
        "Trend fetcher not implemented. Contract: specs/technical.md §1.3"
    )
