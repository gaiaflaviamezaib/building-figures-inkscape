# Step 1: make each panel as its own vector file, already at its final size.
# Saving at final size means 8 pt text stays 8 pt in the figure (no rescaling).

library(ggplot2)
library(dplyr)
library(palmerpenguins)
library(pheatmap)
library(svglite)

dir.create("panels", showWarnings = FALSE)

peng <- penguins |> filter(if_all(c(bill_length_mm:body_mass_g, sex), ~ !is.na(.)))
measures <- c("bill_length_mm", "bill_depth_mm", "flipper_length_mm", "body_mass_g")

# Okabe-Ito colours, readable with colour blindness, used in every panel
species_cols <- c(Adelie = "#E69F00", Chinstrap = "#56B4E9", Gentoo = "#009E73")

theme_fig <- theme_classic(base_size = 8) +
  theme(axis.text = element_text(colour = "black"),
        axis.line = element_line(linewidth = 0.3),
        axis.ticks = element_line(linewidth = 0.3),
        legend.key.size = unit(8, "pt"),
        plot.margin = margin(14, 6, 4, 4))

save_panel <- function(plot, file, width, height) {
  svglite(file, width = width, height = height)
  print(plot)
  invisible(dev.off())
}

# A: PCA of the four measurements
pca <- prcomp(peng[measures], scale. = TRUE)
var_pct <- round(100 * pca$sdev^2 / sum(pca$sdev^2), 1)
pc <- bind_cols(peng, as.data.frame(pca$x[, 1:2]))

a <- ggplot(pc, aes(PC1, PC2, colour = species)) +
  geom_point(size = 0.8, alpha = 0.8) +
  scale_colour_manual(values = species_cols, name = NULL) +
  labs(x = paste0("PC1 (", var_pct[1], "%)"), y = paste0("PC2 (", var_pct[2], "%)")) +
  theme_fig +
  theme(legend.position = "inside", legend.position.inside = c(0.85, 0.85))
save_panel(a, "panels/A.svg", 3.4, 2.6)

# B: bill length vs depth. Pooled, the slope is negative; within each species
# it is positive (Simpson's paradox). The arrow is added in the assembly step.
b <- ggplot(peng, aes(bill_length_mm, bill_depth_mm)) +
  geom_smooth(method = "lm", formula = y ~ x, se = FALSE, colour = "grey50",
              linetype = "dashed", linewidth = 0.4) +
  geom_point(aes(colour = species), size = 0.8, alpha = 0.8) +
  geom_smooth(aes(colour = species), method = "lm", formula = y ~ x, se = FALSE,
              linewidth = 0.5) +
  scale_colour_manual(values = species_cols, guide = "none") +
  labs(x = "bill length (mm)", y = "bill depth (mm)") +
  theme_fig
save_panel(b, "panels/B.svg", 3.4, 2.6)

# C: body mass, every penguin plus the distribution
set.seed(1)  # fixed jitter, so a rebuild gives the same figure
c_plot <- ggplot(peng, aes(species, body_mass_g / 1000, fill = species)) +
  geom_violin(colour = NA, alpha = 0.35) +
  geom_jitter(aes(colour = species), width = 0.15, size = 0.5, alpha = 0.7) +
  stat_summary(fun = median, geom = "crossbar", width = 0.5, linewidth = 0.3) +
  scale_fill_manual(values = species_cols, guide = "none") +
  scale_colour_manual(values = species_cols, guide = "none") +
  labs(x = NULL, y = "body mass (kg)") +
  theme_fig
save_panel(c_plot, "panels/C.svg", 2.6, 2.6)

# D: heatmap of z-scored measurements, penguins clustered
mat <- scale(as.matrix(peng[measures]))
colnames(mat) <- c("bill length", "bill depth", "flipper length", "body mass")
rownames(mat) <- paste0("p", seq_len(nrow(mat)))
annot <- data.frame(species = peng$species, row.names = rownames(mat))

ph <- pheatmap(
  t(mat),
  annotation_col = annot,
  annotation_colors = list(species = species_cols),
  annotation_names_col = FALSE,
  show_colnames = FALSE,
  cluster_rows = FALSE,
  clustering_method = "ward.D2",
  treeheight_col = 20,
  color = colorRampPalette(c("#2166AC", "white", "#B2182B"))(50),
  breaks = seq(-2.5, 2.5, length.out = 51),
  fontsize = 7, border_color = NA,
  silent = TRUE
)
svglite("panels/D.svg", width = 4.2, height = 2.6)
grid::grid.draw(ph$gtable)
invisible(dev.off())

