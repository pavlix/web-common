# web-common

Shared Astro layout, structural Sass, and print-asset tooling for pavlix's
small brochure/marketing sites. Site repositories vendor this repository as a
git submodule and keep only site-specific print composition and asset names.

Provides:

- `src/layouts/Base.astro` — shared page chrome (header, nav, footer)
- `src/styles/_common.scss` — structural Sass (layout, header/nav mechanics,
  spacing) using `!default` variables for colors/fonts, meant to be
  `@use ... with (...)` from each site's own palette file
- `assets/` — shared graphics (logos, icons), if/when needed

Sibling replacement for the Zola-based `zola-business-theme`, now that
sites are built with Astro instead of Zola.
