# Changelog

## ggsegMelbourne 0.0.0.9000

- Added the Melbourne Subcortex Atlas (Tian et al. 2020) at all four
  scales, in both the 3 Tesla
  ([`melbourne_s1()`](https://ggsegverse.github.io/ggsegMelbourne/reference/melbourne.md)
  to
  [`melbourne_s4()`](https://ggsegverse.github.io/ggsegMelbourne/reference/melbourne.md))
  and 7 Tesla
  ([`melbourne_s1_7t()`](https://ggsegverse.github.io/ggsegMelbourne/reference/melbourne.md)
  to
  [`melbourne_s4_7t()`](https://ggsegverse.github.io/ggsegMelbourne/reference/melbourne.md))
  variants. Each is drawn in two coronal and two axial views on the
  cortical ribbon, and carries 3D meshes.
- Colour follows the parcellation hierarchy: one hue per parent
  structure, with its subdivisions in shades of that hue, so a structure
  keeps its colour across scales and hemispheres.
