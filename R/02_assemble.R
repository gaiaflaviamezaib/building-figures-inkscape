# Step 2: assemble the panels into one multi-panel SVG, the way the workshop
# does it by hand in Inkscape: one layer per panel, a layer for the panel
# letters and a layer for annotations. The SVG still opens and edits in
# Inkscape (text stays text), and is exported to PDF and a 300 dpi PNG.

library(rsvg)

dir.create("figure", showWarnings = FALSE)

pt <- 72  # 1 inch = 72 pt, the user unit of the svglite panels

# inline a panel SVG, prefixing its ids so clip paths from different
# panels cannot collide
read_panel <- function(file, prefix) {
  svg <- paste(readLines(file, warn = FALSE), collapse = "\n")
  open_tag <- regmatches(svg, regexpr("<svg[^>]*>", svg))
  view_box <- sub(".*viewBox='([^']*)'.*", "\\1", open_tag)
  body <- sub("(?s)^.*?<svg[^>]*>", "", svg, perl = TRUE)
  body <- sub("(?s)</svg>\\s*$", "", body, perl = TRUE)
  body <- gsub("id='", paste0("id='", prefix, "-"), body, fixed = TRUE)
  body <- gsub("url(#", paste0("url(#", prefix, "-"), body, fixed = TRUE)
  size <- as.numeric(strsplit(view_box, " ")[[1]][3:4])
  list(body = body, w = size[1], h = size[2])
}

layer <- function(id, label, content) {
  sprintf("<g inkscape:groupmode='layer' inkscape:label='%s' id='%s'>\n%s\n</g>",
          label, id, content)
}

place <- function(panel, x, y) {
  sprintf("<svg x='%.2f' y='%.2f' width='%.2f' height='%.2f' viewBox='0 0 %.2f %.2f'>%s</svg>",
          x, y, panel$w, panel$h, panel$w, panel$h, panel$body)
}

# layout (pt): 2 x 2 grid, 7 in wide (double column for most journals)
fig_w <- 7 * pt
gap <- 0.2 * pt
panels <- list(
  A = list(file = "panels/A.svg", label = "A  PCA", x = 0, y = 0),
  B = list(file = "panels/B.svg", label = "B  bill length vs depth", x = 3.6 * pt, y = 0),
  C = list(file = "panels/C.svg", label = "C  body mass", x = 0, y = 2.6 * pt + gap),
  D = list(file = "panels/D.svg", label = "D  heatmap", x = 2.8 * pt, y = 2.6 * pt + gap)
)
fig_h <- 2 * 2.6 * pt + gap

panel_layers <- vapply(names(panels), function(k) {
  p <- panels[[k]]
  layer(paste0("panel-", k), p$label, place(read_panel(p$file, k), p$x, p$y))
}, character(1))

# panel letters: same font, size and offset for every panel
letters_svg <- paste(vapply(names(panels), function(k) {
  sprintf("<text x='%.2f' y='%.2f'>%s</text>", panels[[k]]$x + 2, panels[[k]]$y + 11, k)
}, character(1)), collapse = "\n")
letters_layer <- layer("letters", "panel letters",
  sprintf("<g style='font-family: Arial; font-size: 11pt; font-weight: bold;'>\n%s\n</g>",
          letters_svg))

# annotation in B: arrow to the dashed pooled regression line
bx <- panels$B$x
annot_layer <- layer("annotations", "annotations", paste0(
  "<g style='font-family: Arial; font-size: 7pt; fill: #555555;'>",
  sprintf("<text x='%.2f' y='%.2f' text-anchor='end'>all species pooled</text>", bx + 236, 30),
  "</g>",
  sprintf("<path d='M %.2f %.2f Q %.2f %.2f %.2f %.2f' style='fill: none; stroke: #555555; stroke-width: 0.6;' marker-end='url(#arrow)'/>",
          bx + 215, 35, bx + 234, 64, bx + 225, 110)
))

defs <- paste0(
  "<defs><marker id='arrow' viewBox='0 0 6 6' refX='5' refY='3' markerWidth='6' markerHeight='6' orient='auto'>",
  "<path d='M 0 0 L 6 3 L 0 6 z' style='fill: #555555;'/></marker></defs>"
)

svg <- paste0(
  "<?xml version='1.0' encoding='UTF-8'?>\n",
  sprintf("<svg xmlns='http://www.w3.org/2000/svg' xmlns:xlink='http://www.w3.org/1999/xlink' xmlns:inkscape='http://www.inkscape.org/namespaces/inkscape' width='%.2fpt' height='%.2fpt' viewBox='0 0 %.2f %.2f'>\n",
          fig_w, fig_h, fig_w, fig_h),
  defs, "\n",
  "<rect width='100%' height='100%' style='fill: #FFFFFF;'/>\n",
  paste(panel_layers, collapse = "\n"), "\n",
  annot_layer, "\n",
  letters_layer, "\n",
  "</svg>\n"
)
writeLines(svg, "figure/figure_1.svg", useBytes = TRUE)

rsvg_pdf("figure/figure_1.svg", "figure/figure_1.pdf")
rsvg_png("figure/figure_1.svg", "figure/figure_1.png", width = 7 * 300)
