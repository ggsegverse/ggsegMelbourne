#' Melbourne Subcortex Atlas
#'
#' The Melbourne Subcortex Atlas parcellates the human subcortex from
#' resting-state functional connectivity gradients, at four nested scales.
#' Each atlas is drawn in four views, two coronal and two axial, with the
#' surrounding brain in grey for anatomical context. All contain 2D polygon
#' geometry for [ggseg::geom_brain()] and 3D mesh data for
#' [ggseg3d::ggseg3d()].
#'
#' The scales are hierarchical: every parcel at a finer scale nests inside one
#' parcel of the scale above, so `tian_s1()` regions are unions of `tian_s2()`
#' regions and so on. Colour follows that hierarchy, one hue per parent
#' structure with its subdivisions in shades of that hue, so a structure is
#' recognisable at every scale.
#'
#' The `*_7t()` atlases are the 7 Tesla variants, derived from higher
#' resolution data and parcellated slightly more finely than their 3 Tesla
#' counterparts at the same scale.
#'
#' @section Structures per hemisphere:
#'
#' | Scale | 3T | 7T |
#' |---|---|---|
#' | I | 8 | 8 |
#' | II | 16 | 17 |
#' | III | 25 | 27 |
#' | IV | 27 | 31 |
#'
#' @family ggseg_atlases
#' @family subcortical_atlases
#' @name tian
#'
#' @references Tian Y, Margulies DS, Breakspear M, Zalesky A (2020).
#'   Topographic organization of the human subcortex unveiled with functional
#'   connectivity gradients. Nature Neuroscience 23:1421-1432.
#'   (\doi{10.1038/s41593-020-00711-6})
#'
#' @return A [ggseg.formats::ggseg_atlas] object (subcortical).
#' @examples
#' tian_s1()
#' plot(tian_s1())
NULL


#' @describeIn tian Scale I, 8 structures per hemisphere: hippocampus,
#'   amygdala, nucleus accumbens, pallidum, putamen, caudate, and the
#'   thalamus split into an anterior and a posterior division.
#' @export
tian_s1 <- function() .tian_s1

#' @describeIn tian Scale II, 16 structures per hemisphere. Each scale I
#'   structure splits in two, along an anterior-posterior, medial-lateral or
#'   core-shell axis.
#' @export
tian_s2 <- function() .tian_s2

#' @describeIn tian Scale III, 25 structures per hemisphere.
#' @export
tian_s3 <- function() .tian_s3

#' @describeIn tian Scale IV, 27 structures per hemisphere, the finest
#'   parcellation published for 3 Tesla data.
#' @export
tian_s4 <- function() .tian_s4

#' @describeIn tian Scale I from 7 Tesla data, 8 structures per hemisphere.
#' @export
tian_s1_7t <- function() .tian_s1_7t

#' @describeIn tian Scale II from 7 Tesla data, 17 structures per hemisphere.
#' @export
tian_s2_7t <- function() .tian_s2_7t

#' @describeIn tian Scale III from 7 Tesla data, 27 structures per hemisphere.
#' @export
tian_s3_7t <- function() .tian_s3_7t

#' @describeIn tian Scale IV from 7 Tesla data, 31 structures per hemisphere.
#' @export
tian_s4_7t <- function() .tian_s4_7t
