cat('Generate Figure 2 in main text. \n\n')

if (!require("pacman")) install.packages("pacman")
library(pacman)
pacman::p_load(
  ggplot2, ggthemes, zoo, scales, grid, gridExtra, lattice, tidyverse
)

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

# read topic model results
df = read.csv("./output_cables/frcab_k26_dtmatrix_compact.csv")  # read csv file 

# generate date varaibles
df$quarter = quarters(as.Date(df$date))
df$month = format(as.Date(df$date, format="%d/%m/%Y"),"%m")
df$year = format(as.Date(df$date, format="%d/%m/%Y"),"%Y")

# aggregate data by quarter year
df_agg = aggregate(df, list(Year = df$year, Quarter = df$quarter), mean)
df_agg = df_agg[order(df_agg$Year, df_agg$Quarter),]
df_agg$yrqtr = paste(df_agg$Year,df_agg$Quarter)
df_agg$yrqtr = as.Date(as.yearqtr(df_agg$yrqtr, format = "%Y Q%q"))
df_agg <- df_agg[which(df_agg$yrqtr < "1914-10-01"), ]

# Make list of topics, to plot them.
var_list = names(df_agg)[14:39]

topic25 = ggplot(data=df_agg, aes_string(x=df_agg$yrqtr, y=var_list[26])) + 
  geom_bar(stat="identity") +
  scale_x_date() + theme_few() + labs(x="", y="") + theme(legend.position="none", text = element_text(size=15),plot.title = element_text(size = 16, hjust = 0.5))+ggtitle("War/Alliance")

topic16 = ggplot(data=df_agg, aes_string(x=df_agg$yrqtr, y=var_list[17])) + 
  geom_bar(stat="identity") + 
  scale_x_date() + theme_few() + labs(x="", y="") + theme(legend.position="none", text = element_text(size=15),plot.title = element_text(size = 16, hjust = 0.5))+ggtitle("Diplomacy/Int'l Law")

topic10 = ggplot(data=df_agg, aes_string(x=df_agg$yrqtr, y=var_list[11])) +
  geom_bar(stat="identity") + 
  scale_x_date() + theme_few() + labs(x="", y="") + theme(legend.position="none", text = element_text(size=15),plot.title = element_text(size = 16, hjust = 0.5))+ggtitle("Spain")

topic9 = ggplot(data=df_agg, aes_string(x=df_agg$yrqtr, y=var_list[10])) +
  geom_bar(stat="identity") + 
  scale_x_date() + theme_few() + labs(x="", y="") + theme(legend.position="none", text = element_text(size=15),plot.title = element_text(size = 16, hjust = 0.5))+ggtitle("China")

pdf("./predictive_validity/predictive_validity_plot.pdf")
grid.arrange(topic25, topic16, topic10, topic9, ncol=2)
dev.off()




