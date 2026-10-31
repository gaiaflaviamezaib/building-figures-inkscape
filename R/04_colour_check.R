# Check figure 1 the way a colour-blind reader would see it.
# Renders the figure, simulates deuteranopia, protanopia and tritanopia with
# colorspace, and puts the four versions in one 2 x 2 image.

library(rsvg)
library(colorspace)
library(png)

img <- rsvg("figure/figure_1.svg", width = 1050)  # rows x cols x RGBA, 0 to 1
h <- dim(img)[1]
w <- dim(img)[2]

hex <- rgb(img[, , 1], img[, , 2], img[, , 3])
cols <- unique(hex)  # simulate each colour once, not each pixel

simulate <- function(fun) {
  sim <- col2rgb(fun(cols))[, match(hex, cols)] / 255
  out <- array(1, c(h, w, 3))
  for (k in 1:3) out[, , k] <- sim[k, ]
  out
}

versions <- list(original = img[, , 1:3],
                 deuteranopia = simulate(deutan),
                 protanopia = simulate(protan),
                 tritanopia = simulate(tritan))

gap <- 20
grid <- array(1, c(2 * h + gap, 2 * w + gap, 3))
for (i in seq_along(versions)) {
  r <- (i - 1) %/% 2 * (h + gap)
  c <- (i - 1) %% 2 * (w + gap)
  grid[r + seq_len(h), c + seq_len(w), ] <- versions[[i]]
}
writePNG(grid, "figure/colour_check.png")
