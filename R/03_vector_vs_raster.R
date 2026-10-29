# Why vector: zoom into the same corner of panel B, once from the SVG and
# once from a 72 dpi PNG. The SVG stays sharp at any zoom, the PNG does not.

library(rsvg)

zoom <- "70 100 90 67.5"  # x y width height of the crop, in pt
out_w <- 720

svg <- paste(readLines("panels/B.svg", warn = FALSE), collapse = "\n")
svg <- sub("viewBox='[^']*'", paste0("viewBox='", zoom, "'"), svg)
svg <- sub("width='[^']*' height='[^']*'", "width='360pt' height='270pt'", svg)
rsvg_png(charToRaw(svg), "figure/zoom_vector.png", width = out_w)

# the same panel rasterised at 72 dpi (1 px per pt), as a low-res export would be
rsvg_png("panels/B.svg", "panels/B_72dpi.png", width = 245)
png_b64 <- jsonlite::base64_enc(readBin("panels/B_72dpi.png", "raw", file.size("panels/B_72dpi.png")))
raster <- sprintf(paste0(
  "<svg xmlns='http://www.w3.org/2000/svg' width='360pt' height='270pt' viewBox='%s'>",
  "<image x='0' y='0' width='244.8' height='187.2' style='image-rendering: pixelated'",
  " href='data:image/png;base64,%s'/></svg>"), zoom, png_b64)
rsvg_png(charToRaw(raster), "figure/zoom_raster.png", width = out_w)
