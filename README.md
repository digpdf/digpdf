# digpdf

digpdf converts a PDF to HTML for LLM agents and ingestion pipelines. It can also render a page, or a part of a
page, to PNG, so an agent can look at what the text does not carry.

It reads the text layer of the PDF with [PDFium](https://pdfium.googlesource.com/pdfium/), the PDF engine in Chrome.
It runs no machine learning model and no OCR, and it needs no GPU. The same file gives the same HTML on every run.
Measured over 2,650 PDFs on a three-core server, the median page took 0.1 second.

digpdf works out reading order and tables from where the text stands on the page, the order it is stored in the
file, and drawn lines and fills. It gets some pages wrong. Try it on your own documents.

## Install

    pip install digpdf

This needs Python 3.8 or newer. It installs the `digpdf` command and the Python package. `uv tool install digpdf` and
`pipx install digpdf` work as well.

Without Python, download the archive for Linux, macOS or Windows from the
[releases page](https://github.com/digpdf/digpdf/releases). Unpack it and run `./digpdf` in its folder, or
`.\digpdf.exe` on Windows. Keep the PDFium library next to the program.

## Usage

Convert a PDF to HTML.

    digpdf report.pdf > report.html

Render page 3 to PNG. Pages count from 1.

    digpdf report.pdf 3 > page-3.png

Render a part of page 3. The four numbers are a `data-bbox` copied from the HTML.

    digpdf report.pdf 3 120,40,880,300 > crop.png

In Python, `html()` returns a string and `image()` returns PNG bytes.

```python
import digpdf

html = digpdf.html("report.pdf")
png = digpdf.image("report.pdf", 3)
crop = digpdf.image("report.pdf", 3, "120,40,880,300")
```

There are no options. The PNG has two pixels per PDF point, up to 2,000 pixels on the long side.

If a file cannot be read, nothing is written to stdout, one line on stderr says why, and the exit code is 1. In
Python, `digpdf.Unreadable` is raised.

The HTML looks like this. It is part of a page with a title, a table and a paragraph.

```html
<div data-page="1">
<div data-bbox="122,51,268,63" class="s1">Staff in numbers</div>
<div data-bbox="121,134,717,210" class="s1"><table>
<tr><td>Satisfaction</td><td>2021</td><td>2022</td></tr>
<tr><td>Very satisfied</td><td>41</td><td>44</td></tr>
<tr><td>Satisfied</td><td>38</td><td>37</td></tr>
<tr><td>Not satisfied</td><td>21</td><td>19</td></tr>
</table></div>
<div data-bbox="121,467,527,481" class="s1">A paragraph after the tables, to end the page.</div>
</div>
```

## Design goals

A PDF page has two dimensions and text has one, so every conversion loses something. The goal is to lose as little
as possible of what an agent or a search index needs. Reading order has the highest priority, then tables, then the
breaks between blocks.

The rendered page is the reference. Where the HTML and the page disagree, the HTML is wrong.

A reading error that looks plausible is hard to catch later. The aim is therefore to show where digpdf could not
read something, instead of writing a best guess. Such a place is marked in the HTML, and the agent can ask for its
image.

Where it is unclear whether two things belong together, the aim is to keep them apart. A table cell that was split
in two can usually be put together again by the reader. Two cells that were merged are much harder to take apart.

digpdf does not label content. There are no heading or caption elements. A title is a block like any other, and its
class shows that it is large and bold.

## Why HTML and not Markdown

HTML takes more tokens than Markdown, but it can hold things that plain Markdown cannot.

- Table cells that span several columns or rows, and line breaks inside a cell.
- The page and the box of every block, which an agent needs to ask for the image of a block.
- The marks on places that need vision and on hidden text.
- The font, size and colour of the text.

If you need Markdown, run the HTML through an HTML to Markdown converter. Most converters drop the boxes and the
marks.

## How it differs from other parsers

If your PDFs are scans without a text layer, use a parser with OCR. digpdf only shows where the images are.

Some parsers run layout or vision models and label headings, captions and figures. digpdf runs no model and adds
no labels. It reads the text that is in the file and gives you the image for the rest.

Other tools that read the text layer also give coordinates and render pages. What digpdf adds is having it all in
one document. Every block has its box, places that need vision are marked, hidden text is separated from visible
text, and the image command takes the boxes as they are written.

## The HTML in detail

Every page is a `<div data-page="n">` with the blocks of the page inside it in reading order. A block is a
paragraph, a table, a list, a code block, a figure or a single line such as a title.

A block is a `<div>` with a `data-bbox`, the box around it. The box is four whole numbers, `x0,y0,x1,y1`, on a grid
from 0 to 1000 across the width and the height of the page as it is displayed, with 0,0 in the top left corner.

The class of a text block is the font, size and colour that most of its text has. The classes are defined in one
`<style>` at the top of the document. A paragraph keeps the line breaks it has in the PDF.

Where digpdf recognises these, it writes them with HTML's own elements.

| In the PDF | In the HTML |
|---|---|
| Table | `<table>`, with `colspan` and `rowspan` for merged cells |
| List | `<ul>` or `<ol>` |
| Text on a monospace grid | `<pre>` |
| Bold, italic, underline, strike-through | `<b>`, `<i>`, `<u>`, `<s>` |
| Link | `<a href>` |

A link to `javascript:`, `vbscript:` or `data:` has its target in `data-href` and no `href`, so nothing runs if the
HTML is opened in a browser.

An image is an `<img data-bbox>` at its place in the reading order. It has no `src`. It says where on the page an
image is, and the image command gives you the pixels. A scanned page without a text layer has images and no text.

A place that has to be read from the image has the attribute `data-visual`. digpdf sets it on a figure, a formula, a
chart, text with a broken encoding, and a page it failed to read. The attribute is on a `<div>`, on a `<span>`
inside a paragraph, or on a `<tbody>` inside a table. The words of the text layer are still inside the element, but
they do not say what the page shows. Give the element's `data-bbox` and the page number to the image command, and
read the PNG with a vision model or OCR. Content without the mark can still be read wrong.

Text that is in the file but cannot be seen on the page is not written as text. It is an empty element with the
`hidden` attribute and the text in `data-text`. `data-hidden` says how it is hidden (`offpage`, `clipped`,
`covered`, `invisible`, `samecolour`, `tiny`). An OCR layer over a scanned page is read as ordinary text.

There are no `<sup>` and `<sub>` elements. Text that is raised or lowered in the PDF is set apart from the word with
a space, so 10 to the power of 20 is written `10 20` and not `1020`.

## Limitations

- No OCR. A scanned page comes out as images, and reading them is up to you.
- A PDF that needs a password to open cannot be read.
- digpdf does not repair a damaged file itself. PDFium may repair one while opening it. digpdf then reads what
  PDFium recovered, which may be incomplete, and a line on stderr says that the file is damaged. If PDFium cannot
  open the file, it cannot be read.
- If a single page fails, the other pages are still written. The failed page is one `data-visual` block, and a line
  on stderr says so.
- digpdf sets no limit on the time or the memory a file may take. For files you do not trust, set a timeout and a
  memory limit yourself, for example on a container.

## Platform notes

- On Windows, the built-in Windows PowerShell 5.1 changes what a program writes when it is redirected with `>`. The
  characters of the HTML are changed and the PNG is ruined. The same goes for PowerShell before 7.4 on any system.
  Use `cmd`, PowerShell 7.4 or newer, or the Python package.
- The standalone archives are not signed. On Windows, running the program from a downloaded archive may show
  "Windows protected your PC" (choose More info, then Run anyway). On macOS the program may be blocked until the
  quarantine mark is removed with `xattr -dr com.apple.quarantine FOLDER`. Installing with pip, uv or pipx avoids
  both.

## Problems

Report a file that reads wrong, or a system digpdf does not run on, at https://github.com/digpdf/digpdf/issues

## Licence

digpdf is free to use, also commercially. It is not open source. See LICENSE. It includes PDFium and other
third-party software under their own licences, listed in THIRD-PARTY-NOTICES.txt.
