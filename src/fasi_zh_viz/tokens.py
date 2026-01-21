import json
from importlib import resources

def load_tokens() -> dict:
    with resources.files("fasi_zh_viz").joinpath("data/tokens.json").open("r", encoding="utf-8") as fh:
        return json.load(fh)


def load_css(filename: str) -> str:
    """Lädt eine mitgelieferte CSS-Datei aus dem Package (data/...)."""
    with resources.files("fasi_zh_viz").joinpath(f"data/{filename}").open("r", encoding="utf-8") as fh:
        return fh.read()
