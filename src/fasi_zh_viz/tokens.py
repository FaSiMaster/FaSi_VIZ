import json
from importlib import resources
from typing import Any, Dict, cast


def load_tokens() -> Dict[str, Any]:
    """Lädt `tokens.json` (Single Source of Truth) aus dem Package."""
    path = resources.files("fasi_zh_viz").joinpath("data/tokens.json")
    with path.open("r", encoding="utf-8") as fh:
        return cast(Dict[str, Any], json.load(fh))


def load_css(filename: str) -> str:
    """Lädt eine mitgelieferte CSS-Datei aus dem Package (data/...)."""
    path = resources.files("fasi_zh_viz").joinpath(f"data/{filename}")
    with path.open("r", encoding="utf-8") as fh:
        return fh.read()
