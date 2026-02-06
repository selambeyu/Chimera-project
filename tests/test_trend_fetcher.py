"""
TDD: Asserts that the trend data structure matches the API contract.
Contract: specs/technical.md §1.3 (Trend Data).
These tests SHOULD fail until fetch_trends is implemented and returns valid data.
"""

# Import from skill module (will raise NotImplementedError until implemented)
from skills.skill_fetch_trends.fetch import fetch_trends

TREND_DATA_REQUIRED_KEYS = {
    "source_id",
    "source_type",
    "title",
    "summary",
    "url",
    "published_at",
    "relevance_score",
    "topics",
}
VALID_SOURCE_TYPES = {"news", "social", "market"}


def assert_trend_item_contract(item: dict) -> None:
    """Assert a single trend item matches specs/technical.md §1.3."""
    assert isinstance(item, dict), "Each trend item must be a dict"
    missing = TREND_DATA_REQUIRED_KEYS - set(item.keys())
    assert not missing, f"Trend item missing keys: {missing}"
    assert item["source_type"] in VALID_SOURCE_TYPES
    assert isinstance(item["title"], str)
    assert isinstance(item["summary"], str)
    assert isinstance(item["url"], str)
    assert isinstance(item["relevance_score"], (int, float))
    assert 0 <= item["relevance_score"] <= 1.0
    assert isinstance(item["topics"], list)
    assert all(isinstance(t, str) for t in item["topics"])


def test_trend_fetcher_returns_list() -> None:
    """fetch_trends must return a list (possibly empty)."""
    result = fetch_trends(source_type="news", limit=5)
    assert isinstance(result, list), "fetch_trends must return a list"


def test_trend_fetcher_items_match_api_contract() -> None:
    """Each item returned must match Trend Data schema (specs/technical.md §1.3)."""
    result = fetch_trends(source_type="news", topic="fashion", limit=3)
    assert isinstance(result, list)
    for item in result:
        assert_trend_item_contract(item)


def test_trend_fetcher_accepts_optional_params() -> None:
    """fetch_trends must accept source_type, optional topic and limit."""
    result = fetch_trends(source_type="social", limit=1)
    assert isinstance(result, list)
