# FaSi_VIZ Farbstandard – SafetyCockpit

**Erstellt:** 2026-03-17
**Grundlage:** Farbscan aller .R, .css, .yml Dateien in `SafetyCockpit/`
**CD-Referenz:** Offizielle CD-Farben Kanton Zürich (7 Kernfarben)
**Palett-Quelle:** R-Datenobjekte in `data/` (aus statistikZH/leu Designsystem)

---

## Teil A – CD-Referenzfarben Kanton Zürich

| Name | Hex | Status |
|------|-----|--------|
| Zürichblau | `#005CA9` | CD-Referenz |
| Dunkelblau | `#003B6F` | CD-Referenz |
| Hellblau / Akzent | `#009FE3` | CD-Referenz |
| Schwarz | `#000000` | CD-Referenz |
| Weiss | `#FFFFFF` | CD-Referenz |
| Grau (Text) | `#4A4A49` | CD-Referenz |
| Grau (Hintergrund) | `#F0F0F0` | CD-Referenz |

---

## Teil B – Gefundene Paletten (aus R-Datenpaketen)

### B.1 ktz_palette (54 Einträge – statistikZH Infografik-Palette)

| Index | Hex | Farbbeschreibung | Konform |
|-------|-----|-----------------|---------|
| [1] | `#009EE0` | Cyan-Blau (Primärfarbe) | PRÜFEN – nahe an Hellblau/Akzent `#009FE3` |
| [2] | `#FFCC00` | Gelb | FaSi-intern (Infografik) |
| [3] | `#3EA743` | Grün | FaSi-intern (Infografik) |
| [4] | `#E2001A` | Rot | FaSi-intern (Infografik) |
| [5] | `#0076E0` | Blau | PRÜFEN – nahe an Zürichblau |
| [6] | `#EB690B` | Orange | FaSi-intern (Infografik) |
| [7] | `#00A1A3` | Türkis | FaSi-intern (Infografik) |
| [8] | `#885EA0` | Violett | FaSi-intern (Infografik) |
| [9] | `#E30059` | Magenta | FaSi-intern (Infografik) |
| [10]–[54] | Diverse | Helle Abstufungen der obigen | FaSi-intern (Infografik) |

> **Hinweis:** Die komplette ktz_palette stammt aus dem statistikZH `leu`-Designsystem und ist für Datenvisualisierungen im Kanton Zürich vorgesehen. Sie gilt als offiziell sanktioniert, ist aber nicht Teil der 7 CD-Kernfarben.

### B.2 Akzentfarben

| Name | Hex | Konform |
|------|-----|---------|
| Blau | `#0076BD` | **KONFORM** – korrigiert auf Figma-Token `colors.accent.blau` (war `#0070B4`) |
| Dunkelblau | `#00407C` | PRÜFEN – nahe an CD Dunkelblau `#003B6F` |
| Türkis | `#00797B` | FaSi-intern (Infografik) |
| Grün | `#1A7F1F` | FaSi-intern (Infografik) |
| Bordeaux | `#B01657` | FaSi-intern (Infografik) |
| Magenta | `#D40053` | FaSi-intern (Infografik) |
| Violett | `#7F3DA7` | FaSi-intern (Infografik) |
| Grau 60 | `#666666` | PRÜFEN – nächste ZH-Entsprechung: Black 60 ZH `#666666` (Grautoene) ✓ |

> **WICHTIG:** `Akzentfarben[["Blau"]] = #0070B4` ist **falsch** gemäss CLAUDE.md und FaSi_VIZ-Standard. Korrekt: `#0076BD` (Figma-Token `colors.accent.blau`). Muss in der nächsten Palettenversion korrigiert werden.

### B.3 AkzentfarbenSoft

| Name | Hex | Konform |
|------|-----|---------|
| Softblau | `#EDF5FA` | FaSi-intern (Pastell) |
| Blaugrau | `#E0E8EE` | FaSi-intern (Pastell) |
| Softtürkis | `#E8F3F2` | FaSi-intern (Pastell) |
| Softgrün | `#EBF6EB` | FaSi-intern (Pastell) |
| Softbordeaux | `#F6E3EA` | FaSi-intern (Pastell) |
| Softrot | `#FCEDF3` | FaSi-intern (Pastell) |
| Softviolett | `#ECE2F1` | FaSi-intern (Pastell) |
| Black 10 ZH | `#F0F0F0` | **KONFORM** – CD Grau Hintergrund |

### B.4 Funktion

| Name | Hex | Verwendung | Konform |
|------|-----|-----------|---------|
| Cyan | `#009EE0` | Bootstrap `info` | PRÜFEN – nahe an CD Hellblau `#009FE3` |
| Rot | `#D93C1A` | Bootstrap `danger` | FaSi-intern (funktional: Fehler/Alert) |
| Grün | `#1A7F1F` | Bootstrap `success` | FaSi-intern (funktional: Erfolg/OK) |

### B.5 Infografiken

| Name | Hex | Konform |
|------|-----|---------|
| Dunkelblau | `#00407C` | PRÜFEN – nahe an CD Dunkelblau `#003B6F` |
| Türkis | `#00797B` | FaSi-intern (Infografik) |
| Aquamarine | `#0FA693` | FaSi-intern (Infografik) |
| Dunkelgrün | `#00544C` | FaSi-intern (Infografik) |
| Grün | `#1A7F1F` | FaSi-intern (Infografik) |
| Grasgrün | `#8A8C00` | FaSi-intern (Infografik) |
| Braun | `#96170F` | FaSi-intern (Infografik) |
| Orange | `#DC7700` | FaSi-intern (Infografik) |
| Rot | `#D93C1A` | FaSi-intern (Ampel/Status) |
| Magenta | `#D40053` | FaSi-intern (Infografik) |
| Bordeaux | `#B01657` | FaSi-intern (Infografik) |
| Dunkelrot | `#7A0049` | FaSi-intern (Infografik) |
| Dunkelviolett | `#54268E` | FaSi-intern (Infografik) |
| Violett | `#7F3DA7` | FaSi-intern (Infografik) |
| Hellviolett | `#9572D5` | FaSi-intern (Infografik) |
| Cyan | `#009EE0` | FaSi-intern (Infografik) |
| Blau | `#0076BD` | **KONFORM** – korrigiert (war `#0070B4`) |

### B.6 Grautoene

| Name | Hex | Konform |
|------|-----|---------|
| Black 100 ZH | `#000000` | **KONFORM** – CD Schwarz |
| Black 80 ZH | `#333333` | PRÜFEN – innerhalb ZH Grauton-System |
| Black 60 ZH | `#666666` | PRÜFEN – ZH Grauton-System; CD Grau Text = `#4A4A49` |
| Black 40 ZH | `#949494` | PRÜFEN – innerhalb ZH Grauton-System |
| Black 20 ZH | `#CCCCCC` | PRÜFEN – innerhalb ZH Grauton-System |
| Black 10 ZH | `#F0F0F0` | **KONFORM** – CD Grau Hintergrund |
| Black 5 ZH | `#F7F7F7` | PRÜFEN – sehr nahe an CD Grau Hintergrund |

---

## Teil C – Hardcodierte Farben (direkt in .R-Dateien)

| Wert | Hex-Equivalent | Datei | Kontext | Konform |
|------|---------------|-------|---------|---------|
| `#1f77b4` | `#1F77B4` | lagebericht_utils.R | PDF-Titel/Untertitel | **ABWEICHUNG** – Matplotlib-Standardblau, kein ZH CD |
| `#999` / `#999999` | `#999999` | lagebericht_utils.R | Tabellenrahmen | PRÜFEN – nahe Black 40 ZH `#949494` |
| `#f3f3f3` | `#F3F3F3` | lagebericht_utils.R | Tabellenkopf Hintergrund | PRÜFEN – nahe Black 10 ZH `#F0F0F0` |
| `#666` / `#666666` | `#666666` | lagebericht_utils.R | Seitenfuß Text | PRÜFEN – entspricht Black 60 ZH |
| `#FFF5CC` | `#FFF5CC` | gauge_plots.R | Gauge-Bereich Mitte (gelb) | PRÜFEN – entspricht ktz_palette[29] |
| `#ffd5cc` | `#FFD5CC` | gauge_plots.R | Gauge-Bereich oben (rot) | PRÜFEN – nahe ktz_palette[31] `#FFC6CD` |
| `#666666` | `#666666` | mapdensity_mod.R | Kantons-Polygonrahmen | PRÜFEN – entspricht Black 60 ZH |
| `#b00020` | `#B00020` | safety_cockpit.R | Fehler-Meldung (Inline) | **ABWEICHUNG** – Material Design Error Red, kein ZH CD |
| `#00000010` | Schwarz 6% alpha | cumul_plot.R etc. | Transparente Füllflächen | KONFORM – technischer Hilfswert |
| `#00000000` | Vollständig transparent | cumul_plot.R etc. | Unsichtbare Linien | KONFORM – technischer Hilfswert |

---

## Teil D – Named CSS/R-Farben (Unfallschwere und Status)

| R-Name | Hex-Equivalent | Datei | Kontext | Konform |
|--------|---------------|-------|---------|---------|
| `lightsteelblue2` | `#BCD2EE` | theming.R | Unfälle mit Sachschaden | **FaSi-intern** – funktional begründet |
| `gold` | `#FFD700` | theming.R | Unfälle mit Leichtverletzten | **FaSi-intern** – funktional begründet |
| `darkgoldenrod1` | `#FFB90F` | theming.R | Unfälle mit Schwerverletzten | **FaSi-intern** – funktional begründet |
| `tomato2` | `#EE4000` | theming.R | Unfälle mit Getöteten | **FaSi-intern** – funktional begründet |
| `grey50` | `#7F7F7F` | theming.R | Status unbekannt | PRÜFEN – verwende Black 40 ZH `#949494` |
| `white` | `#FFFFFF` | theming.R | Hintergrund, Marker | **KONFORM** – CD Weiss |
| `black` | `#000000` | theming.R | Text, Marker Umriss | **KONFORM** – CD Schwarz |
| `lightgreen` | `#90EE90` | lagebericht_utils.R | Status "Reduktion" (gut) | **FaSi-intern** – Ampelfarbe, funktional |
| `lightgrey` | `#D3D3D3` | lagebericht_utils.R | Status "null" | PRÜFEN – verwende Black 20 ZH `#CCCCCC` |
| `orange` | `#FFA500` | lagebericht_utils.R | Status "Warnung" | **FaSi-intern** – Ampelfarbe, funktional |
| `red` | `#FF0000` | lagebericht_utils.R | Status "Alert" | **FaSi-intern** – Ampelfarbe, funktional |
| `beige` | `#F5F5DC` | lagebericht_utils.R | Jahres-Spalten Hintergrund | **ABWEICHUNG** – kein ZH CD Match |
| `grey` | `#BEBEBE` (R) | gauge_plots.R | Schwellenwert-Linie | PRÜFEN – verwende Black 40 ZH `#949494` |
| `lightgrey` | `#D3D3D3` | kapobericht_mod.R | Laufendes Jahr Hintergrund | PRÜFEN – verwende Black 20 ZH `#CCCCCC` |
| `transparent` | `#FFFFFF00` | mapdensity_mod.R | Polygon-Füllung | KONFORM – technischer Hilfswert |

---

## Teil E – Excel-Kategoriefarben (kapobericht_mod.R)

Diese Farben stammen aus Microsoft Excel-Standardpaletten und sind für die visuelle Unterscheidung von Verkehrsteilnehmergruppen im XLSX-Export.

| Stil | Hex (Kopfzeile) | Hex (Datenzeile) | Kategorie | Konform |
|------|----------------|-----------------|-----------|---------|
| Allgemein | `#A6A6A6` | `#F2F2F2` | Gesamt-Kennzahlen | PRÜFEN |
| Fussgänger | `#C6E0B4` | `#E2EFDA` | Fussgänger/FäG | FaSi-intern (Kategorie) |
| E-Trotti | `#F4B084` | `#F8CBAD` | E-Trottinett | FaSi-intern (Kategorie) |
| Velo | `#B4C6E7` | `#D9E1F2` | Fahrrad | FaSi-intern (Kategorie) |
| E-Bike | `#FFE699` | `#FFF2CC` | E-Bike | FaSi-intern (Kategorie) |
| Motorrad | `#ACB9CA` | `#D6DCE4` | Motorrad | FaSi-intern (Kategorie) |
| Personenwagen | `#F8CBAD` | `#FCE4D6` | Personenwagen | FaSi-intern (Kategorie) |
| Kinder | `#A9D08E` | `#C6E0B4` | Kinder (≤14 J.) | FaSi-intern (Kategorie) |
| Senioren | `#8EA9DB` | `#B4C6E7` | Senioren (≥65 J.) | FaSi-intern (Kategorie) |
| FG/FGS | `#FFD966` | `#FFE699` | Fussgängerstreifen | FaSi-intern (Kategorie) |

---

## Teil F – FaSi_VIZ Farbstandard (Empfehlung)

### F.1 Kantonale Kernfarben (direkt übernehmen)

| Name | Hex | Verwendungszweck | Konform |
|------|-----|-----------------|---------|
| ZH Schwarz | `#000000` | Text, Rahmen | ja |
| ZH Weiss | `#FFFFFF` | Hintergründe, Marker | ja |
| ZH Grau Hintergrund | `#F0F0F0` | Panels, Accordion, Tabellenkopf | ja |
| ZH Hellgrau (5%) | `#F7F7F7` | Subtile Hintergründe | ja |
| ZH Grau 20% | `#CCCCCC` | Trennlinien, deaktiviert | ja |
| ZH Grau 40% | `#949494` | Sekundärtext, Icons | ja |
| ZH Grau 60% | `#666666` | Fusszeilen, Untertitel | ja |
| ZH Grau 80% | `#333333` | Primärtext | ja |

### F.2 Akzentfarben (statistikZH leu – offiziell sanktioniert)

| Name | Hex | Verwendungszweck | Konform |
|------|-----|-----------------|---------|
| Blau | `#0076BD` | Primary-Farbe App, Navbar | ja (Figma-Token) |
| Dunkelblau | `#00407C` | Dunklere Variante | PRÜFEN |
| Türkis | `#00797B` | Sekundärfarbe | FaSi-intern (leu) |
| Grün | `#1A7F1F` | Success, Reduktion | FaSi-intern (leu) |

> **Hinweis:** Der aktuelle Wert `#0070B4` in `data/Akzentfarben.rda` muss auf `#0076BD` korrigiert werden.

### F.3 Infografik-Farben (statistikZH leu)

Alle 54 Farben der ktz_palette sowie die benannten Infografiken-Farben gelten als **FaSi-intern aus statistikZH Designsystem** und können für Datenvisualisierungen verwendet werden.

### F.4 Funktionale Statusfarben (FaSi-intern)

| Name | Hex | Verwendungszweck | Konform |
|------|-----|-----------------|---------|
| Status Grün | `#1A7F1F` | Ampel grün, Reduktion | FaSi-intern |
| Status Orange | `#DC7700` | Ampel gelb, Warnung | FaSi-intern |
| Status Rot | `#D93C1A` | Ampel rot, Alert | FaSi-intern |
| Status Grau | `#949494` | Unbekannt, kein Wert | FaSi-intern |

> **Empfehlung:** Named CSS Colors (`red`, `orange`, `lightgreen`, `grey50`) durch diese Hex-Werte ersetzen.

### F.5 Unfallschwere-Farben (FaSi-intern, funktional begründet)

| Name | Hex (Empfehlung) | Aktueller Wert | Verwendungszweck |
|------|-----------------|----------------|-----------------|
| Sachschaden | `#BCD2EE` | `lightsteelblue2` | Unfälle mit Sachschaden |
| Leichtverletzt | `#FFD700` | `gold` | Leichtverletzte |
| Schwerverletzt | `#FFB90F` | `darkgoldenrod1` | Schwerverletzte |
| Getötet | `#EE4000` | `tomato2` | Getötete |

> Diese Farben sind funktional begründet (ASTRA Unfalltypenklassierung) und haben keine direkte kantonale Entsprechung. Named Colors sollten durch explizite Hex-Werte ersetzt werden.

### F.6 Zu korrigierende Farben

| Aktueller Wert | Datei | Empfehlung | Begründung |
|---------------|-------|-----------|------------|
| `#1f77b4` | lagebericht_utils.R | `#0076BD` oder `#0070B4` | Matplotlib-Blau ersetzen durch ZH Blau |
| `#b00020` | safety_cockpit.R | `#D93C1A` | Material Design Red ersetzen durch Funktion Rot |
| `beige` | lagebericht_utils.R | `#F0F0F0` | Kein ZH CD Match, ersetzen durch ZH Grau Hintergrund |
| `lightgrey` | lagebericht_utils.R | `#CCCCCC` | Named Color ersetzen durch Black 20 ZH |
| `orange` | lagebericht_utils.R | `#DC7700` | Named Color ersetzen durch Infografiken Orange |
| `red` | lagebericht_utils.R | `#D93C1A` | Named Color ersetzen durch Funktion Rot |
| `lightgreen` | lagebericht_utils.R | `#1A7F1F` | Named Color ersetzen durch Funktion Grün |
| `grey50` | theming.R | `#949494` | Named Color ersetzen durch Black 40 ZH |
| `grey` | gauge_plots.R | `#949494` | Named Color ersetzen durch Black 40 ZH |
| `#999` | lagebericht_utils.R | `#949494` | Annähern an Black 40 ZH |
| `#f3f3f3` | lagebericht_utils.R | `#F0F0F0` | Annähern an Black 10 ZH |
| ~~`Akzentfarben Blau`~~ | data/Akzentfarben.rda | `#0076BD` | **erledigt** (2026-03-17) |

---

## Teil G – Abschlussbericht

### Statistik

| Kategorie | Anzahl |
|-----------|--------|
| **Farben total gefunden** | ~85 einzigartige Farbwerte |
| Konform (exakter CD-Match) | **4** (#000000, #FFFFFF, #F0F0F0, #F7F7F7) |
| PRÜFEN (aus statistikZH leu, ZH-sanktioniert) | **~60** (ktz_palette, Akzentfarben, Grautoene etc.) |
| FaSi-intern ohne kantonale Entsprechung | **~15** (Schwere-Farben, Ampel, Excel-Kategorien) |
| ABWEICHUNG – nicht konform | **4** (#1f77b4, #b00020, beige, Akzentfarben Blau #0070B4) |

### Empfehlungen

1. **Sofort korrigieren – Prio 1:**
   - ~~`Akzentfarben[["Blau"]]` in `data/Akzentfarben.rda`~~ → **erledigt** (2026-03-17, `#0070B4` → `#0076BD`)
   - `#1f77b4` in `lagebericht_utils.R` (Zeilen 61, 70) → **nicht umgesetzt** (städtischer Bericht, Farbe bleibt)
   - `#b00020` in `safety_cockpit.R` → **nicht weiterverfolgt**

2. **Mittelfristig – Prio 2:**
   - Named R-CSS-Farben (`red`, `orange`, `lightgreen`, `gold`, `grey`, etc.) durch explizite Hex-Werte aus der leu-Palette ersetzen
   - `beige` durch `#F0F0F0` ersetzen
   - Grau-Näherungen (`#999`, `#f3f3f3`, `lightgrey`) an offizielle Grautoene angleichen

3. **Zur Kenntnis – Prio 3:**
   - Die ktz_palette/Infografiken-Farben aus dem statistikZH `leu`-Paket sind offiziell für ZH-Datenvisualisierungen vorgesehen und können weiterverwendet werden
   - Schwere-Farben (Sachschaden/Leichtverletzt/Schwerverletzt/Getötet) sind durch ASTRA-Klassierung begründet und bleiben als FaSi-intern bestehen
   - Excel-Kategoriefarben sind rein funktional für die Berichterstattung und werden nicht im Screen-UI verwendet

---

*Dieser Standard gilt ausschliesslich für das SafetyCockpit-Projekt (intern, nicht öffentlich). Keine Veröffentlichung auf GitHub.*
