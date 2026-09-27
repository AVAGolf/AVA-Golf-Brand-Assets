# AVA Golf Brand Assets

Official brand assets for [AVA Golf](https://avagolf.com).

> Our brand is built on consistency — not as a constraint, but as a mark of confidence. Built for serious golfers and the people who share their ambition.

---

## Download

**[⬇ Download AVA_Golf_Brand_Pack.zip](https://brand.avagolf.com/files/AVA_Golf_Brand_Pack.zip)**

The zip is always the current version of the pack. Any push that changes the pack's contents rebuilds and republishes it under the next version number (see [Versioning](#versioning)).

---

## What's included

```
AVA_Golf_Brand_Pack/
├── 01 Logos/                      Primary, secondary, and tertiary logo files (SVG, PNG)
├── 02 Ready to Use Brand Marks/   Pre-formatted marks — Square, Landscape, and Press
├── 03 Colors/                     Color swatches (Adobe .ase)
├── 04 Typography/                 Brand typefaces and licenses
├── 05 Brand Element Assets/       Halftones, textures, and supporting graphic elements
├── VERSION.txt                    Version, publish date, and source commit
└── CHANGES.md                     What changed since the previous version
```

### Logos
- **Primary** — full logo in PNG (web, print, square social) and vector
- **Secondary** — stacked logo and standalone icon
- **Tertiary** — full-color, green, mid, mono-black, and white variants (wordmark, icon, stacked, side-by-side)

### Colors
Swatches are provided as an Adobe swatch exchange file (`AVAGolf_Colors_Swatches.ase`). Palette tokens:

- **Greens** — `Green-300`, `Green-500`, `Green-700`, `Green-900`, `Bright-Green-500`
- **Dark Greens** — `Dark-Green-300`, `Dark-Green-500`, `Dark-Green-700`, `Dark-Green-900`
- **Yellows** — `Yellow-300`, `Yellow-500`
- **Neutrals** — `Black`, `White`, `Grey-300`

### Typography
- **Google Sans Flex** — primary typeface
- **Construct Mono** — display / accent monospace
- **DM Mono** — supporting monospace

---

## Versioning

The pack carries a version number, shown on [brand.avagolf.com](https://brand.avagolf.com) and in the zip's `VERSION.txt`.

- **Automatic** — every push to `main` that adds, changes, renames, or removes a file in the pack publishes the next patch version, `1.0.0` → `1.0.1`. Pushes that only touch this README, `.gitignore`, or `.github/` publish nothing.
- **Bigger steps** — put `[minor]` in a commit message for a notable addition (`1.0.1` → `1.1.0`), or `[major]` for a redesign (`1.1.0` → `2.0.0`). The largest marker since the last version wins.
- **Manual run** — *Actions → Build & Publish Brand Pack → Run workflow* publishes any unpublished change with the bump you pick. With nothing new to publish, it rebuilds and re-uploads the current version as-is, which is how to repair a bad upload.
- **Manifest** — [`files/brand-pack.json`](https://brand.avagolf.com/files/brand-pack.json) describes the current pack: version, publish date, size, SHA-256, and commit. brand.avagolf.com reads it when it builds.
- **Only the current pack is kept** — each version overwrites the one zip; no older zip is stored anywhere. Every version gets a git tag (`brand-pack-vX.Y.Z`) and a [release](https://github.com/AVAGolf/AVA-Golf-Brand-Assets/releases) listing its changes, but releases carry notes, not files. An older version can always be rebuilt from its tag.
- **Showing the new number straight away** — the site picks up a new version at its next deploy. To make that immediate, add a `BRAND_DEPLOY_TOKEN` Actions secret to this repository: a fine-grained token with Actions read/write on `AVAGolf/brand.avagolf.com` only. Each publish then starts the site's deploy.

---

## Usage

These assets are provided for press, partners, and approved third-party use.

- Do not alter, distort, or recolor the logo
- Do not use AVA Golf branding to imply endorsement without prior written approval
- For sponsorship, partnership, or licensing inquiries: [marketing@avagolf.com](mailto:marketing@avagolf.com)

---

## Full brand guide

The interactive brand guide is available at [brand.avagolf.com](https://brand.avagolf.com).

---

© AVA Golf, Inc. All rights reserved.
