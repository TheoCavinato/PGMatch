library(argparse)
library(dplyr)
library(data.table)
library(ggplot2)
library(ggpubr)
library(MetBrewer)

#------------------------------------------------------------------------------#
# Parameters
#------------------------------------------------------------------------------#

parser <- ArgumentParser()
parser$add_argument("--concat_data", required=T)

parser$add_argument("--out_pdf", required=T)
args <- parser$parse_args()

# debugging
#args$concat_data = "/scratch/tcavinat/Phenotype_inference_attack/Idfx_vs_pgmatch_mem_time//Plots/concat_time_mem.tsv"
#args$out_pdf = "/scratch/tcavinat/Phenotype_inference_attack/Idfx_vs_pgmatch_mem_time//Plots/time_mem.pdf"

#------------------------------------------------------------------------------#
# Import data
#------------------------------------------------------------------------------#

concat_dt = fread(args$concat_data, sep=" ")

# sum idfx train and idfx test
sum_concat_dt = subset(concat_dt, method == "pgmatch")
sum_concat_dt$method = "PGMatch"
merge_idfx = merge(subset(concat_dt, method == "idfx_test"), subset(concat_dt, method == "idfx_train"),by = c("n_test", "n_train", "nbr_pheno", "itr"))
merge_idfx$time_spent = merge_idfx$time_spent.x + merge_idfx$time_spent.y
merge_idfx$mem_kbytes = merge_idfx$mem_kbytes.x + merge_idfx$mem_kbytes.y
merge_idfx$method = "IDEFIX"

new_concat_dt = rbind(sum_concat_dt, merge_idfx[, c("method", "n_test", "n_train", "nbr_pheno", "itr", "time_spent", "mem_kbytes")])

new_concat_dt$method = factor(new_concat_dt$method, levels=c("PGMatch", "IDEFIX"))
new_concat_dt$n_test = factor(new_concat_dt$n_test, levels=sort(unique(new_concat_dt$n_test)))

#------------------------------------------------------------------------------#
# Make plot
#------------------------------------------------------------------------------#

# ── 2. Summarise: mean ± sd per (method, nbr_pheno) ────────────
df_summary <- new_concat_dt |>
  group_by(method, nbr_pheno, n_test) |>
  summarise(
    mean_time = mean(time_spent),
    mean_mem = mean(mem_kbytes/1000),
        min_time  = min(time_spent),
    max_time  = max(time_spent),
        min_mem  = min(mem_kbytes/1000),
    max_mem  = max(mem_kbytes/1000),
    .groups = "drop"
  )


# ── 3. Plot ─────────────────────────────────────────────────────
plot_function = function(df, x_axis, y_axis, min_y, max_y, cur_title, x_lab, y_lab){
#my_palette = c("#8282aa", "#e2aba7")
my_palette = c( "#e2aba7", "#8282aa")
p = ggplot(df,
       aes_string(x = x_axis, y = y_axis, fill = "method")) +

  # bars
  geom_col(position = position_dodge()) +
           
  # error bars  ← swap sd_time for se_time if you prefer std error
  geom_errorbar(
    aes_string(ymin = min_y,
        ymax = max_y),
    position = position_dodge(),
    linewidth = 0.6
  ) +

  labs(x = x_lab,
       y = y_lab,
       fill = "Method",
       title = cur_title) +

  scale_fill_manual(values= my_palette ) +
  scale_colour_manual(values = my_palette) +
  theme_bw() +
  theme(plot.title = element_text(hjust=0.5),
  legend.position = c(0.2,0.8),
  legend.background = element_rect(color="black"),
  legend.title = element_blank())
}

p_time_per_p = plot_function(subset(df_summary, n_test == 1000), "nbr_pheno", "mean_time", "min_time", "max_time", "Time comparison", "Number of phenotypes", "Time spent (seconds s)")
p_mem_per_p = plot_function(subset(df_summary, n_test == 1000), "nbr_pheno", "mean_mem", "min_mem", "max_mem", "Memory comparison", "Number of phenotypes", "Max memory resident size (Mbytes)") + theme(legend.position = "none")
p_time_per_n = plot_function(subset(df_summary, nbr_pheno == 10), "n_test", "mean_time", "min_time", "max_time", "Time comparison", "Size of testing set", "Time spent (seconds s)") + theme(legend.position = "none")
p_mem_per_n = plot_function(subset(df_summary, nbr_pheno == 10), "n_test", "mean_mem", "min_mem", "max_mem", "Memory comparison", "Size of testing set", "Max memory resident size (Mbytes)") + theme(legend.position = "none")

p_final = ggarrange(p_time_per_p, p_mem_per_p, p_time_per_n, p_mem_per_n, ncol=2, nrow=2, labels="AUTO")

ggsave(args$out_pdf, width=10, height=10)
