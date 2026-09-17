# Create the Melbourne Subcortex Atlas (Tian et al. 2020) for ggseg
#
# The Melbourne parcellations ship as labelled volumes on the FSL-MNI152 grid
# with no anatomical context. As with the other MNI152 subcortical atlases in
# the ggsegverse, they are embedded into the fsaverage5 aseg with
# ggseg.extra::prepare_subcortical_mni152(), which registers them through the
# fixed mni152.register.dat transform, replaces the lumped aseg structures they
# subdivide, and returns a merged volume plus colour table for the subcortical
# pipeline. aseg_context() then demotes the surrounding brain to grey.
#
# Four hierarchical scales (S1-S4) are published, each in a 3T (1 mm) and a 7T
# (1.6 mm) variant. The 7T volumes are resampled onto the 1 mm grid first,
# because mni152.register.dat is defined against that template.
#
# Source: https://github.com/anniegbryant/subcortex_visualization
#   (atlas_info/MNI152NLin6Asym/Melbourne_*), originally
#   https://github.com/yetianmed/subcortex
# Reference: Tian Y, Margulies DS, Breakspear M, Zalesky A (2020).
#   Nature Neuroscience 23:1421-1432. DOI: 10.1038/s41593-020-00711-6
#
# Requires: ggseg.extra, ggseg.formats, FreeSurfer 7.4.1 with fsaverage5.
#
# Run with: Rscript data-raw/make_melbourne.R [scale ...]

library(ggseg.extra)
library(ggseg.formats)

future::plan(future::sequential)
progressr::handlers("cli")
progressr::handlers(global = TRUE)

fs_home <- Sys.getenv("FREESURFER_HOME", "/Applications/freesurfer/7.4.1")
Sys.setenv(FREESURFER_HOME = fs_home)
Sys.setenv(SUBJECTS_DIR = file.path(fs_home, "subjects"))

data_raw <- here::here("data-raw")
source_dir <- file.path(data_raw, "source")

# Melbourne ids start at 1 and would collide with the aseg ids kept as grey
# context, so every parcel is shifted clear before it is stamped in.
#
# The shift has to clear the aseg ids from below and stay under 1000 from
# above. Labels from 1000 to 2999 are where an aparc+aseg puts its cortical
# parcels, and a pipeline that finds parcels in that range reads them as the
# cortex: the parcels become the brain silhouette and the cortical ribbon
# never gets drawn.
id_offset <- 300L

scales <- commandArgs(trailingOnly = TRUE)
if (length(scales) == 0) {
  scales <- c("S1", "S2", "S3", "S4", "S1_7T", "S2_7T", "S3_7T", "S4_7T")
}

capitalise_token <- function(x) {
  lowercase_only <- x == tolower(x)
  x[lowercase_only] <- sub("^(.)", "\\U\\1", x[lowercase_only], perl = TRUE)
  x
}

hemi_from_name <- function(x) {
  ifelse(
    grepl("(_L|-lh)$", x),
    "Left",
    ifelse(grepl("(_R|-rh)$", x), "Right", NA_character_)
  )
}

structure_from_name <- function(x) sub("(_[LR]|-[lr]h)$", "", x)

atlas_label <- function(structure, hemi) {
  titled <- vapply(
    strsplit(structure, "_", fixed = TRUE),
    function(tokens) paste(capitalise_token(tokens), collapse = "_"),
    character(1)
  )
  paste(titled, hemi, sep = "_")
}

# The scales are nested, so colour follows the hierarchy: one hue per parent
# structure, and the subdivisions of that structure spread across shades of it.
# A structure keeps its hue at every scale and on both sides, so the four
# atlases read as one family rather than four unrelated colour schemes.
structure_family <- function(structure) {
  family <- tolower(sub("_.*$", "", structure))
  ifelse(family == "gp", "pallidum", family)
}

shades_of <- function(colour, n) {
  if (n == 1L) {
    return(colour)
  }
  hsv <- grDevices::rgb2hsv(grDevices::col2rgb(colour))
  grDevices::hsv(
    h = hsv[1],
    s = seq(max(0.25, hsv[2] - 0.30), min(1, hsv[2] + 0.15), length.out = n),
    v = seq(min(1, hsv[3] + 0.25), max(0.35, hsv[3] - 0.20), length.out = n)
  )
}

structure_colours <- function(structure) {
  family <- structure_family(structure)
  families <- sort(unique(family))
  hues <- grDevices::hcl.colors(length(families), palette = "Dark 3")
  names(hues) <- families

  colours <- character(length(structure))
  for (fam in families) {
    members <- sort(unique(structure[family == fam]))
    shades <- shades_of(hues[[fam]], length(members))
    colours[family == fam] <- shades[match(structure[family == fam], members)]
  }
  colours
}

read_melbourne_lut <- function(scale) {
  lookup <- utils::read.csv(
    file.path(source_dir, sprintf("Melbourne_%s_lookup.csv", scale)),
    header = FALSE,
    col.names = c("idx", "name"),
    fileEncoding = "UTF-8-BOM"
  )

  structure <- structure_from_name(lookup$name)
  hemi <- hemi_from_name(lookup$name)
  if (anyNA(hemi)) {
    cli::cli_abort(
      "No hemisphere suffix on {.val {lookup$name[is.na(hemi)]}}."
    )
  }

  rgb <- grDevices::col2rgb(structure_colours(structure))

  data.frame(
    idx = lookup$idx + id_offset,
    label = atlas_label(structure, hemi),
    R = as.integer(rgb[1, ]),
    G = as.integer(rgb[2, ]),
    B = as.integer(rgb[3, ]),
    A = 0L,
    stringsAsFactors = FALSE
  )
}

# The published 7T volumes sit on a 1.6 mm grid. mni152.register.dat targets
# the 1 mm template, so they are resampled onto the 3T volume's grid first;
# both share the same world affine, which makes --regheader exact.
resample_to_mni1mm <- function(volume, reference, outfile) {
  status <- system2(
    "mri_vol2vol",
    c(
      "--mov",
      shQuote(volume),
      "--targ",
      shQuote(reference),
      "--regheader",
      "--interp",
      "nearest",
      "--o",
      shQuote(outfile)
    )
  )
  if (status != 0 || !file.exists(outfile)) {
    cli::cli_abort("mri_vol2vol failed for {.path {volume}}")
  }
  outfile
}

offset_volume <- function(scale, work_dir) {
  src <- file.path(source_dir, sprintf("Melbourne_%s.nii.gz", scale))
  if (!file.exists(src)) {
    cli::cli_abort("Source not found: {.path {src}}")
  }

  vol <- RNifti::readNifti(src)
  arr <- as.array(vol)
  storage.mode(arr) <- "integer"
  shifted <- array(0L, dim = dim(arr))
  hit <- arr > 0L
  shifted[hit] <- arr[hit] + id_offset

  outfile <- file.path(work_dir, sprintf("melbourne_%s_offset.nii.gz", scale))
  RNifti::writeNifti(RNifti::asNifti(shifted, reference = vol), outfile)

  if (!identical(dim(arr), c(182L, 218L, 182L))) {
    outfile <- resample_to_mni1mm(
      outfile,
      file.path(source_dir, "Melbourne_S1.nii.gz"),
      file.path(work_dir, sprintf("melbourne_%s_1mm.nii.gz", scale))
    )
  }
  outfile
}

# geom_brain() paints rows in order, so the last one lands on top. Sorting by
# structure with the two sides adjacent keeps a structure at the same depth as
# its contralateral twin, and the grey silhouette leads because it is the
# background the rest sits on and the only geometry present in every view.
draw_order <- function(atlas) {
  drawn <- atlas_geom(atlas)$label
  is_silhouette <- grepl("^cortex", drawn)
  by_structure <- function(x) {
    x[order(
      toupper(sub("_(Left|Right)$", "", x)),
      toupper(x),
      method = "radix"
    )]
  }
  atlas_structure_reorder(
    atlas,
    c(by_structure(drawn[is_silhouette]), by_structure(drawn[!is_silhouette]))
  )
}

build_scale <- function(scale) {
  cli::cli_h1("Melbourne Subcortex {scale}")

  # Wiped rather than reused: contours left over from an earlier slab layout
  # are re-read by the pipeline and land in the atlas with no matching view,
  # which fails deep inside the view packing rather than where it went wrong.
  work_dir <- file.path(data_raw, tolower(scale))
  unlink(work_dir, recursive = TRUE)
  dir.create(work_dir, showWarnings = FALSE, recursive = TRUE)

  lut <- read_melbourne_lut(scale)
  volume <- offset_volume(scale, work_dir)

  merged <- prepare_subcortical_mni152(
    input_volume = volume,
    labels = lut$idx,
    lut = lut,
    output_file = file.path(
      work_dir,
      sprintf("melbourne_%s_aseg.nii.gz", scale)
    )
  )

  slabs <- subcortical_slabs(
    merged$volume,
    labels = lut$idx,
    coronal = 2,
    axial = 2,
    pad = 2
  )

  raw <- create_subcortical_from_volume(
    input_volume = merged,
    atlas_name = paste0("melbourne_", tolower(scale)),
    output_dir = work_dir,
    slabs = slabs,
    skip_existing = FALSE,
    cleanup = FALSE
  )

  # Post-creation, so retuning any of it is seconds rather than a rebuild. The
  # parcels are grown a little to survive at plotting size; the silhouette is
  # not, since dilating it closes the sulci. Simplify before smoothing, or the
  # dropped vertices put the voxel staircase back.
  #
  # The two are smoothed at different strengths. The parcels are small, blocky
  # and read as shapes, so they take a heavy pass; the silhouette is a gyrified
  # ribbon whose detail *is* the anatomy, and smoothing it that hard closes the
  # sulci and fills the interior back in.
  atlas <- raw |>
    aseg_context(
      focus = paste(lut$label, collapse = "|"),
      match_on = "label"
    ) |>
    atlas_view_gather() |>
    atlas_dilate(0.6, exclude = "^cortex") |>
    atlas_simplify(keep = 0.2, labels = "^cortex") |>
    atlas_simplify(keep = 0.35, exclude = "^cortex") |>
    atlas_smooth(smoothness = 0.3, labels = "^cortex") |>
    atlas_smooth(smoothness = 0.9, exclude = "^cortex") |>
    draw_order()

  cli::cli_alert_success(
    "{length(atlas_labels(atlas))} structures in \\
     {length(atlas_views(atlas))} views"
  )
  atlas
}

sysdata_path <- here::here("R", "sysdata.rda")
if (file.exists(sysdata_path)) {
  load(sysdata_path)
}

# Saved after each scale rather than once at the end, so a scale that fails
# does not discard the hour of pipeline runs before it.
for (scale in scales) {
  assign(paste0(".melbourne_", tolower(scale)), build_scale(scale))

  built <- ls(all.names = TRUE, pattern = "^\\.melbourne_")
  save(list = built, file = sysdata_path, compress = "xz", version = 3)
  cli::cli_alert_success(
    "Saved {length(built)} atlas{?es} to {.path {sysdata_path}}"
  )
}
