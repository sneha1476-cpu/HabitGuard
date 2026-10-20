"""HabitGuard ML feature schema and input validation."""

from collections.abc import Mapping

import pandas as pd

FEATURE_NAMES = [
    "total_screen_time",
    "social_media_time",
    "entertainment_time",
    "communication_time",
    "gaming_time",
    "productivity_time",
    "number_of_apps",
    "number_of_sessions",
    "late_night_usage",
    "most_used_app_time",
]

CATEGORY_FEATURE_NAMES = [
    "social_media_time",
    "entertainment_time",
    "communication_time",
    "gaming_time",
    "productivity_time",
]


def build_feature_frame(features: Mapping[str, object]) -> pd.DataFrame:
    """Validate one usage record and preserve model feature order."""
    missing = [name for name in FEATURE_NAMES if name not in features]
    if missing:
        raise ValueError(
            f"Missing required feature(s): {', '.join(missing)}"
        )

    values: dict[str, int] = {}

    for name in FEATURE_NAMES:
        value = features[name]

        if isinstance(value, bool) or not isinstance(value, int):
            raise ValueError(f"Feature '{name}' must be an integer")

        if value < 0:
            raise ValueError(f"Feature '{name}' cannot be negative")

        values[name] = value

    total = values["total_screen_time"]

    if any(values[name] > total for name in CATEGORY_FEATURE_NAMES):
        raise ValueError("A category's usage cannot exceed total screen time")

    category_total = sum(
        values[name] for name in CATEGORY_FEATURE_NAMES
    )

    if category_total > total:
        raise ValueError(
            "The sum of category usage cannot exceed total screen time"
        )

    if values["most_used_app_time"] > total:
        raise ValueError(
            "Most-used app time cannot exceed total screen time"
        )

    return pd.DataFrame([values], columns=FEATURE_NAMES)