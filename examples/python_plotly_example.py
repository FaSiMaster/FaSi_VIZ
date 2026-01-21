from fasi_zh_viz.tokens import load_tokens
from fasi_zh_viz.plotly_theme import apply_plotly_defaults
from fasi_zh_viz.validators import validate_palette_against_background, validate_text_contrast, warn_if_too_many_categories

import plotly.express as px

t = load_tokens()
apply_plotly_defaults(t, base_font_px=12)

df = px.data.gapminder().query("year==2007 and continent=='Europe'")
fig = px.scatter(df, x="gdpPercap", y="lifeExp", size="pop", color="country", hover_name="country")
fig.show()

print(validate_palette_against_background(list(t["colors"]["infographics_palette"].values()), t["infographics_rules"]["background_default"]))
print(validate_text_contrast(t["colors"]["grays"]["black60"], t["infographics_rules"]["background_default"], is_large_text=False))
print(warn_if_too_many_categories(9))
