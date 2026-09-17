atlases <- list(
  melbourne_s1 = list(atlas = melbourne_s1, per_hemi = 8L),
  melbourne_s2 = list(atlas = melbourne_s2, per_hemi = 16L),
  melbourne_s3 = list(atlas = melbourne_s3, per_hemi = 25L),
  melbourne_s4 = list(atlas = melbourne_s4, per_hemi = 27L),
  melbourne_s1_7t = list(atlas = melbourne_s1_7t, per_hemi = 8L),
  melbourne_s2_7t = list(atlas = melbourne_s2_7t, per_hemi = 17L),
  melbourne_s3_7t = list(atlas = melbourne_s3_7t, per_hemi = 27L),
  melbourne_s4_7t = list(atlas = melbourne_s4_7t, per_hemi = 31L)
)

for (nm in names(atlases)) {
  local({
    spec <- atlases[[nm]]
    name <- nm

    describe(paste0(name, "()"), {
      it("is a subcortical ggseg_atlas", {
        atlas <- spec$atlas()
        expect_s3_class(atlas, "ggseg_atlas")
        expect_s3_class(atlas, "subcortical_atlas")
        expect_true(ggseg.formats::is_ggseg_atlas(atlas))
      })

      it("has the published number of structures per hemisphere", {
        core <- spec$atlas()$core
        expect_identical(nrow(core), spec$per_hemi * 2L)
        expect_identical(
          as.integer(table(core$hemi)[c("left", "right")]),
          rep(spec$per_hemi, 2L)
        )
      })

      it("has 2D polygon geometry in four views", {
        expect_true(ggseg.formats::is_atlas_polygon(spec$atlas()))
        expect_length(ggseg.formats::atlas_views(spec$atlas()), 4)
      })

      it("has a named palette covering every label", {
        pal <- ggseg.formats::atlas_palette(spec$atlas())
        expect_type(pal, "character")
        expect_setequal(names(pal), spec$atlas()$core$label)
      })

      it("has 3D meshes for every label", {
        meshes <- ggseg.formats::atlas_meshes(spec$atlas())
        expect_setequal(meshes$label, spec$atlas()$core$label)
      })

      it("gives both hemispheres of a structure the same colour", {
        atlas <- spec$atlas()
        pal <- ggseg.formats::atlas_palette(atlas)
        structure <- sub("_(Left|Right)$", "", names(pal))
        per_structure <- tapply(unname(pal), structure, function(x) {
          length(unique(x))
        })
        expect_true(all(per_structure == 1))
      })
    })
  })
}

describe("melbourne_s1()", {
  it("names the thalamic divisions", {
    expect_setequal(
      grep("^thalamus", melbourne_s1()$core$region, value = TRUE),
      rep(c("thalamus anterior", "thalamus posterior"), 2)
    )
  })

  it("renders with ggseg", {
    skip_if_not_installed("ggseg")
    expect_doppelganger(
      "melbourne_s1-2d",
      ggseg::brain_test_plot(melbourne_s1())
    )
  })
})

describe("melbourne_s4()", {
  it("renders with ggseg", {
    skip_if_not_installed("ggseg")
    expect_doppelganger(
      "melbourne_s4-2d",
      ggseg::brain_test_plot(melbourne_s4())
    )
  })
})

describe("the scales nest", {
  it("splits every scale I structure into finer parcels", {
    parents <- unique(sub("_(Left|Right)$", "", melbourne_s1()$core$label))
    children <- unique(sub("_(Left|Right)$", "", melbourne_s4()$core$label))
    expect_gt(length(children), length(parents))
  })
})
