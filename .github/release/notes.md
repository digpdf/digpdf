    uvx digpdf report.pdf > report.html
    npx digpdf report.pdf > report.html

`pip install digpdf` and `npm install digpdf` also work, or download the archive for your platform below. See the
README for details.

**New**

- digpdf runs in JavaScript, in Node and in browsers through WebAssembly, with the same output byte for byte. On
  npm as `digpdf`, with `npx digpdf` as the command line.
- Form fields. What is typed in a field is in `<span data-field>`, and check boxes and radio buttons are ☒ or ☐.
  Pages with form fields render to PNG as they are filled in.
- An OCR layer already in the PDF is kept as hidden text marked `data-ocr`, with the bounding box of the scan.
- The HTML has a default style for reading in a browser, with a white page, a little space between blocks and thin
  lines around table cells.

**Improved extraction**

- Tables. Group headers span the columns they head, header rows are found over their ruling lines, and currency
  signs and closing brackets stay with their values.
- Charts. Legends, axis labels and pie slices stay in the chart's `data-visual` block.
- Underline and strikethrough are marked where they are drawn, also across spaces and parts of words.
- Paragraphs are split where the space between lines shows it, and a running header above a page's own title is no
  longer marked as a heading.
- Ligatures, letter-spaced words and text typed in comb fields are read as the words they are.
