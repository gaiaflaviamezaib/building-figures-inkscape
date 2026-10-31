# Rebuild everything: Rscript run_all.R (from the repo root)

packages <- c("ggplot2", "dplyr", "palmerpenguins", "pheatmap", "svglite", "rsvg", "jsonlite", "colorspace", "png")
missing <- packages[!vapply(packages, requireNamespace, logical(1), quietly = TRUE)]
if (length(missing)) install.packages(missing, repos = "https://cloud.r-project.org")

for (script in sort(list.files("R", pattern = "[.]R$", full.names = TRUE))) {
  message("== ", script)
  source(script, local = new.env())
}
message("done")
