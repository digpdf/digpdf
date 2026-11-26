# digpdf

**PDF to HTML for AI agents**

[![PyPI](https://img.shields.io/pypi/v/digpdf)](https://pypi.org/project/digpdf/)
[![npm](https://img.shields.io/npm/v/digpdf)](https://www.npmjs.com/package/digpdf)

digpdf converts PDFs to HTML that keeps reading order, tables and formatting intact for language models and ingestion pipelines.

It also flags hidden text and marks charts, formulas and scans as visuals. Every block carries a bounding box so facts can be traced to the PDF and any area or full page can be rendered to PNG.

## Why digpdf?

Vision models work wonders, but rendering and processing every page as an image costs both time and compute. It can also obscure which boxes are form fields, what text is hidden and where links lead. digpdf is designed exactly to complement the OCR or vision model in your agent harness or ingestion pipeline. It supplies the necessary information and acts as a gate to save resources for when they are actually needed.

- Free, commercial use included
- No GPU required
- Offline, PDFs stay local
- Zero dependencies
- Full traceability
- Reproducible HTML

## Command line, Python and JavaScript

The Python package includes a prebuilt binary that bundles PDFium. The npm package runs digpdf and PDFium in WebAssembly.

### Command line

```bash
uvx digpdf report.pdf > report.html
npx digpdf report.pdf > report.html
```

```bash
# Install with uv tool install digpdf, pip install digpdf or npm install -g digpdf
digpdf report.pdf > report.html
digpdf report.pdf 3 > page-3.png
# Render a data-bbox area
digpdf report.pdf 3 404,262,593,292 > block.png
```

### Python

```python
# Install with uv add digpdf or pip install digpdf
import digpdf

html = digpdf.html("report.pdf")
page = digpdf.image("report.pdf", 3)  # PNG bytes
block = digpdf.image("report.pdf", 3, "404,262,593,292")
```

### JavaScript (Node.js)

```js
// Install with npm install digpdf
import { readFile } from "node:fs/promises";
import { load } from "digpdf";

const pdf = await readFile("report.pdf");
const digpdf = await load();

const { html, notes } = await digpdf.html(pdf, "report.pdf");
const page = await digpdf.image(pdf, 3); // PNG as a Uint8Array
const block = await digpdf.image(pdf, 3, "404,262,593,292");
```

Pass the PDF as a `Uint8Array`, an `ArrayBuffer` or a Node.js `Buffer`. Conversion and rendering block the calling thread. In the browser, run digpdf in a module Web Worker and allow `'unsafe-eval'` in the Content Security Policy.

### Platforms

- Python package
  - Linux, macOS and Windows
  - x86-64 and ARM64
  - Python 3.8+
- npm package
  - Node.js 20+
  - Browsers

## Why HTML?

Unlike Markdown and plain text, HTML keeps merged and empty table cells, font sizes and colours, line breaks inside cells and superscripts, so 14 with source note 3 does not read as 143. HTML also gives pages and blocks a standard place for attributes that record page numbers and coordinates, flag hidden text and mark running headers, footers, charts and scans. Structure affects semantics. Better to use a few more tokens than lose critical signals.

### Attributes

| Attribute | Description |
| --- | --- |
| `data-page` | Page number, starting at 1, on the `<div>` that wraps each page. |
| `data-bbox` | Left, top, right and bottom coordinates on a 0 to 1000 grid from the top left of the page. Pass them to digpdf to render that area to PNG. |
| `class="s3"` | The block’s main style, defined as CSS in the HTML `<head>`. |
| `data-head` | A guessed heading (ranked by size) or a table header row. |
| `data-header`, `data-footer` | Running headers and footers. |
| `data-visual` | A chart, formula, scan or page the text layer cannot capture. Render it to PNG with digpdf. |
| `data-ocr` | Hidden text from an OCR layer already in the PDF, with the scan’s bounding box. |
| `data-hidden` | How text is hidden (`offpage`, `clipped`, `covered`, `invisible`, `samecolour` or `tiny`). |
| `data-text` | Hidden text outside the visible flow, including OCR text. |
| `data-field` | What is typed in a form field. Check boxes and radio buttons are ☒ or ☐. |

### Hidden text

A model can read `data-text` in raw HTML. Before passing the HTML to a model, keep OCR text and remove `data-text` from hidden elements without `data-ocr` to reduce prompt injection risk. See the [Python example](#filter-and-extend-the-html) below.

#### Filter and extend the HTML

```bash
uv add digpdf beautifulsoup4
# or pip install digpdf beautifulsoup4
```

Remove `data-text` from hidden elements without `data-ocr`

```python
import digpdf
from bs4 import BeautifulSoup

soup = BeautifulSoup(digpdf.html("report.pdf"), "html.parser")
for el in soup.select("[data-hidden]:not([data-ocr])"):
    el.attrs.pop("data-text", None)  # keeps data-hidden and data-bbox
html_for_the_model = str(soup)
```

### Traceability

The HTML `<head>` records the digpdf version in `<meta name="generator">` and the source PDF’s SHA-256 hash in `<meta name="source">`. Parsing the same PDF with the same digpdf version produces byte-identical HTML.

## Licence

See LICENSE. digpdf includes PDFium and other third-party software under their own licences, listed in
THIRD-PARTY-NOTICES.txt.

## Links

- [digpdf](https://digpdf.com)
- [GitHub](https://github.com/digpdf/digpdf)
- [GitHub releases](https://github.com/digpdf/digpdf/releases)
- [PyPI](https://pypi.org/project/digpdf/)
- [npm](https://www.npmjs.com/package/digpdf)
