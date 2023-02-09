cat('Generate Figure 1 in appendix. \n\n')

if (!require("pacman")) install.packages("pacman")
library(pacman)
pacman::p_load(
  ggplot2, ggthemes, ggrepel
)

set.seed(42)

# set working directory
LocationOfThisScript = function() # Function LocationOfThisScript returns the location of this .R script (may be needed to source other files in same dir)
{
  this.file = NULL
  # This file may be 'sourced'
  for (i in -(1:sys.nframe())) {
    if (identical(sys.function(i), base::source)) this.file = (normalizePath(sys.frame(i)$ofile))
  }
  
  if (!is.null(this.file)) return(dirname(this.file))
  
  # But it may also be called from the command line
  cmd.args = commandArgs(trailingOnly = FALSE)
  cmd.args.trailing = commandArgs(trailingOnly = TRUE)
  cmd.args = cmd.args[seq.int(from=1, length.out=length(cmd.args) - length(cmd.args.trailing))]
  res = gsub("^(?:--file=(.*)|.*)$", "\\1", cmd.args)
  
  # If multiple --file arguments are given, R uses the last one
  res = tail(res[res != ""], 1)
  if (0 < length(res)) return(dirname(res))
  
  # Both are not the case. Maybe we are in an R GUI?
  return(NULL)
}
current.dir = LocationOfThisScript()
setwd(current.dir)

# similarity data
sim_data = read.csv("./topic_similarity/frcab_topicsim.csv")  # read csv file 
sim_data['ln_prevalence'] = log(sim_data['prevalence'])
names(sim_data)[names(sim_data) == 'id'] <- 'topic_id'

# label data
label_data = read.csv("./topic_similarity/topic_labels.csv")  # read csv file

sim_data = merge(sim_data, label_data, by='topic_id')

# Plot topic similarity
plot = ggplot(sim_data, aes(x=sim_x, y=sim_y)) +
  geom_point(aes(size = ln_prevalence, color = factor(junk), alpha = 0.6)) + 
  geom_text_repel(aes(label=topic_label), 
                  size=3,
                  point.padding = 5) + 
  theme_minimal() + 
  labs(x="", y="") + 
  theme(legend.position="none") + 
  scale_size(range = c(.5, 8))

plot + scale_color_manual(values=c("#4d4d4d", "#c2c2c2"))

ggsave(file="./topic_similarity/frcab_topic_similarity2.pdf") 



