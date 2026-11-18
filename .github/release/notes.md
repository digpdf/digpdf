    uv tool install digpdf

`pip install digpdf` also works, or download the archive for your platform below. See the README for details.

**New in the output**

- Headings are tagged with `data-head="n"`, table header rows with `data-head`, and page headers and footers with
  `data-header` and `data-footer`. These are attributes, so the text itself is unchanged.
- Superscript and subscript are output as `<sup>` and `<sub>`.
- The `<head>` contains the PDF metadata (language, title, author, description and keywords), the digpdf version and
  the SHA-256 hash of the PDF.

**Improved extraction**

- Tables. Ruling lines define the columns where a table has them. Multi-line header rows are merged into one row,
  currency symbols stay with their values, images and icons inside cells stay in their cells, and side-by-side tables
  are kept apart.
- Rotated and skewed pages, and rotated regions within a page, are deskewed before they are read.
- Lists, hanging indents, margin notes and line numbers are recognized.
- Fonts without a ToUnicode map or cmap are decoded when another subset of the same font in the file has a cmap.
- Word segmentation follows the spacing on the page, text that PDFium drops as a duplicate is kept, a correction
  drawn over covered text replaces it, and metadata stored as UTF-8 without a byte order mark is decoded correctly.
