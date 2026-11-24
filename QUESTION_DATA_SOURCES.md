# Embedded question-bank data notices

ASCENT ships its question facts directly in `index.html`; it makes no runtime data requests. The large factual archive is deliberately limited to fixed, prompt-scoped answers rather than open-ended word puzzles.

## Selection and validation

- **10,000 city-to-country routes** use city names that are unique after the game’s answer normalisation, have a recorded population of at least 20,000, and are capped at 225 routes per country/territory code to avoid a handful of countries dominating the archive.
- **Country/capital routes** are limited to a curated list of independently governed countries plus Taiwan, Kosovo, and Palestine. To avoid contested or de-facto-only capital claims, Nauru and Palestine are excluded from this capital subset (they can still appear in city-to-country routes). South Africa accepts Pretoria, Cape Town, and Bloemfontein; Bolivia, Eswatini, and Sri Lanka accept their relevant multiple capital/government-seat answers.
- **Element routes** use the 118 current element names/symbols; names 113–118 use the current IUPAC names.
- **U.S. routes** cover the 50 states and their state capitals.
- All facts are embedded and matched only against the displayed prompt’s explicit answer set. No typed answer is sent to analytics.

## Source packages and notices

The build-time curation used these packages. Their data are embedded as a curated subset; the packages themselves are not runtime dependencies.

- `countries-list` 3.4.1 — country names and capital data — MIT License, Copyright (c) 2014 Annexare Studio.
- `all-the-cities` 3.1.0 — city names, country codes, and population values — MIT License, Copyright (c) 2018 Nabil Ashraf. Its documentation identifies the upstream city dataset as derived from GeoNames data.
- `periodic-table` 0.0.5 — periodic-element baseline — Copyright (c) 2015 Chris Andrejewski. The six then-temporary element names are updated in ASCENT’s curated data to Nihonium, Flerovium, Moscovium, Livermorium, Tennessine, and Oganesson.

### MIT License

Copyright (c) 2014 Annexare Studio

Copyright (c) 2018 Nabil Ashraf

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

### Periodic-table permission notice

Copyright (c) 2015, Chris Andrejewski <christopher.andrejewski@gmail.com>

Permission to use, copy, modify, and/or distribute this software for any
purpose with or without fee is hereby granted, provided that the above
copyright notice and this permission notice appear in all copies.

THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION
OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN
CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
