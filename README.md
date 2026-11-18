# digpdf

**PDF to HTML for agents and pipelines. Fast, grounded, and with minimal information loss.**

[![PyPI](https://img.shields.io/pypi/v/digpdf)](https://pypi.org/project/digpdf/)

digpdf converts a PDF to HTML for LLM agents and ingestion pipelines. It can also render a page, or a part of a page,
to PNG, so an agent can look at the visual information, or a pipeline can escalate to OCR.

## Quick start

```bash
uv tool install digpdf
digpdf report.pdf > report.html
```

```python
import digpdf  # uv add digpdf

html = digpdf.html("report.pdf")
```

## Why digpdf?

Most PDFs with a text layer can be read quickly and accurately from the text and its geometry. The geometry includes
the bounding box of every glyph, the content stream order, and vector graphics such as ruling lines and cell shading.
The risk is silent information loss, such as a table read across its columns, a chart reduced to stray numbers, or
hidden text mixed into the visible text.

digpdf returns all of this in one pass. You get the text in reading order, tables with their structure, and a
bounding box for every block. Headings and other guesses are attributes, hidden text is kept separate, and blocks
with visual content are flagged. What to do with it is decided downstream.

### How do agents and pipelines use it?

They read the HTML first. It is fast to process, and for most pages it is all they need. When a block is flagged with
`data-visual`, they render that block or the whole page to PNG. An agent looks at the image, and a pipeline runs OCR
or a vision model on it and replaces the block with the result.

```bash
digpdf report.pdf 3 > page-3.png
digpdf report.pdf 3 404,262,593,292 > block.png   # the block's data-bbox
```

### Why no OCR or vision model?

The text layer already contains the exact text, and extracting it is fast and deterministic. digpdf extracts what is
in the file and flags the blocks whose content the text layer does not capture, such as scanned pages, charts and
formulas. Those blocks can then be processed with the OCR or vision model of your choice.

### Does digpdf guess?

Yes, but only in attributes. Headings get `data-head="n"`, table header rows get `data-head`, and page headers and
footers get `data-header` and `data-footer`. The text itself is never changed, so you decide downstream whether to
use the guesses.

### What about hidden text?

Text that is not visible on the page, such as white text on a white background, text outside the page, and clipped,
covered or very small text, is kept separate and flagged `hidden`, so it is not read as part of the content. Hidden
text is a common vector for prompt injection.

### Why HTML?

HTML can represent what Markdown cannot, such as merged table cells, bounding boxes and flags. LLMs read it well, and
stripping the tags gives plain text for a search index.

### Why no options?

There is one output, and it contains everything. What to keep, how to chunk and what to render is decided downstream,
where the requirements are known.

### How fast is it?

A typical page takes under a tenth of a second on one CPU core. No GPU is needed, and no external model is loaded.

### Is the output deterministic?

Yes. The same file produces the same HTML on every run and on every platform.

### What does it run on?

Linux, macOS and Windows, on x86-64 and ARM64. digpdf is a single binary that ships with
[PDFium](https://pdfium.googlesource.com/pdfium/), the PDF engine used in Chrome. Nothing is downloaded at runtime.

## Use

```bash
digpdf report.pdf > report.html                  # the PDF as HTML
digpdf report.pdf 3 > page-3.png                 # page 3 as PNG
digpdf report.pdf 3 120,40,880,300 > block.png   # a block of page 3, by its data-bbox
```

```python
html = digpdf.html("report.pdf")
png = digpdf.image("report.pdf", 3)
block = digpdf.image("report.pdf", 3, "120,40,880,300")
```

Pages are numbered from 1. Rendered PNGs have 2 pixels per PDF point and at most 2,000 pixels on the long side.

Scanned pages are output as `<img>` elements, ready for OCR, and an existing OCR layer is extracted as text. Damaged
files are read as PDFium repairs them, with a warning on stderr. If a page fails, the remaining pages are still
written, and the failed page becomes a single `data-visual` block. For password-protected files and files that
PDFium cannot open, digpdf writes nothing to stdout, prints an error message to stderr and exits with code 1. In
Python, they raise `digpdf.Unreadable`. When processing untrusted files, set your own time and memory limits.

`pip install digpdf` and `pipx install digpdf` also work, with Python 3.8 or newer. Without Python, download the
archive for your platform from the [releases](https://github.com/digpdf/digpdf/releases), unpack it, and keep the
PDFium library next to the binary.

## Output format

```html
<div data-page="1">
<div data-bbox="122,51,268,63" class="s1" data-head="1">Staff in numbers</div>
<div data-bbox="121,134,717,210" class="s2"><table>
<tr data-head><td>Satisfaction</td><td>2021</td><td>2022</td></tr>
<tr><td>Very satisfied</td><td>41</td><td>44</td></tr>
<tr><td>Not satisfied</td><td>21</td><td>19</td></tr>
</table></div>
<div data-bbox="121,467,527,481" class="s2">A paragraph after the table.</div>
</div>
```

Each page is a `<div data-page="n">` containing its blocks in reading order. A block is a paragraph, table, list,
code block, figure or single line. `data-bbox="x0,y0,x1,y1"` is the block's bounding box in coordinates from 0 to
1000 relative to the page width and height, with the origin at the top left, and can be passed directly to the render
command. The CSS `class` gives the font, size and colour of most of the block's text, as defined in the `<style>`
element in the head.

| PDF content | HTML |
|---|---|
| Table | `<table>`, merged cells with `colspan` and `rowspan` |
| List | `<ul>` or `<ol>` |
| Monospaced text | `<pre>` |
| Bold, italic, underline, strikethrough | `<b>`, `<i>`, `<u>`, `<s>` |
| Superscript, subscript | `<sup>`, `<sub>`, preceded by a space, as in `10 <sup>20</sup>` |
| Link | `<a href>`, or `data-href` for `javascript:`, `vbscript:` and `data:` URLs |
| Image | `<img data-bbox>` without `src`, rendered from its bounding box when needed |
| Visual content (figures, charts, formulas, text with a broken encoding) | `data-visual` on a `<div>`, `<span>` or `<tbody>` |
| Hidden text | an empty element with `hidden`, the text in `data-text` and the hiding method in `data-hidden` (`offpage`, `clipped`, `covered`, `invisible`, `samecolour` or `tiny`) |
| Heading | `data-head="n"`, where 1 is the largest heading style |
| Table header row | `<tr data-head>` |
| Page header and footer | `data-header`, `data-footer` |

The `<head>` contains the PDF metadata in `<html lang>`, `<title>` and `<meta>` tags (author, description, keywords,
creator, producer and dates), the digpdf version in `generator`, and the SHA-256 hash of the PDF in `source`.

## Windows and macOS

- Windows PowerShell 5.1 and PowerShell versions before 7.4 re-encode output redirected with `>`, which corrupts the
  HTML and PNG files. Use `cmd`, PowerShell 7.4 or newer, or the Python package.
- The archives are not code-signed. On Windows, choose More info and then Run anyway. On macOS, run
  `xattr -dr com.apple.quarantine FOLDER`. Installing with uv, pip or pipx avoids both.

## Problems

Please report PDFs that digpdf should read better, or platforms it should support, in the
[issues](https://github.com/digpdf/digpdf/issues).

## Licence

digpdf is free to use, also commercially. It is not open source. See LICENSE. It includes PDFium and other
third-party software under their own licences, listed in THIRD-PARTY-NOTICES.txt.
