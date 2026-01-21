from typing import List, Tuple

def verantwortliche_stellen_html(entries: List[Tuple[str, str]]) -> str:
    title = "Für dieses Thema zuständig:"
    chips = "\n".join([f"<a class='fasi-chip' href='{url}'>{label}</a>" for label, url in entries])
    return f"""<section class="fasi-responsible-stellen" aria-label="{title}">
  <h2>{title}</h2>
  <div class="fasi-chip-group">
    {chips}
  </div>
</section>"""
