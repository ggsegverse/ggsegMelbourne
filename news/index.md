# Changelog

## ggsegTian 0.0.0.9000

- Added the Melbourne Subcortex Atlas (Tian et al. 2020) at all four
  scales, in both the 3 Tesla
  ([`tian_s1()`](https://ggsegverse.github.io/ggsegTian/reference/tian.md)
  to
  [`tian_s4()`](https://ggsegverse.github.io/ggsegTian/reference/tian.md))
  and 7 Tesla
  ([`tian_s1_7t()`](https://ggsegverse.github.io/ggsegTian/reference/tian.md)
  to
  [`tian_s4_7t()`](https://ggsegverse.github.io/ggsegTian/reference/tian.md))
  variants. Each is drawn in two coronal and two axial views on a grey
  brain silhouette, and carries 3D meshes.
- Colour follows the parcellation hierarchy: one hue per parent
  structure, with its subdivisions in shades of that hue, so a structure
  keeps its colour across scales and hemispheres.
