cat('Generate Figure 1 in main text. \n\n')

if (!require("pacman")) install.packages("pacman")
library(pacman)
pacman::p_load(
  zoo, chron
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
cables <- read.csv("./output_cables/frcab_k26_dtmatrix_compact.csv") 

# Fix dates
cables$date <- as.Date(cables$date, format = '%d/%m/%Y')
cables$date.interp <- na.approx(cables$date, na.rm=F)  
cables$date[cables$date < as.Date('1870/01/01')] <- NA
cables <- cables[cables$date < as.Date('1915-01-01'),]

# Create plot
pdf('./descriptives/corpus_timeseries.pdf')
hist(cables$date.interp, breaks = 100, freq=T, main='',
     las=1, axes=F, xlab='Year')
axis(1, at = seq(from=min(cables$date, na.rm=T), to = max(cables$date, na.rm=T),
                 length.out=20),
     labels = month.day.year(seq(from=min(cables$date, na.rm=T), to = max(cables$date, na.rm=T),
                  length.out=20))$year, las=2)
axis(2, las=1)
dev.off()
