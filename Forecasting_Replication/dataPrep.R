# Data preparation for prediction

# Clear the working space
rm(list=ls())

#setwd('~/Dropbox/diplomatic_prediction/Forecasting/Replication/')
### Prepare working space

# Import/install relevant libraries
#install.packages('pacman')
library(pacman)

pacman::p_load(chron, fields, knitr, MASS, gridExtra, grid, ggplot2,
               ROCR, texreg, pracma, caret, mlbench, dplyr, readxl, lubridate, readr)

set.seed(504)




### Import Data

#### Import Cable Topics data

# dat1 <- read.csv('frcab_k26_dtmatrix_compact.csv')
dat <- read.csv('../topic_models/output_cables/frcab_k26_dtmatrix_compact.csv')

#Generate date variables

dat$date <- as.Date(dat$date, format='%d/%m/%Y' )
dat$year <- month.day.year(dat$date)$year
dat$month <- month.day.year(dat$date)$month
dat$week <- round(as.numeric(format(as.Date(dat$date), "%U"))/4)*4

#Aggregate the topics by month
dat.ag <- aggregate(data.frame(dat), by=list(dat$year, dat$month), FUN=mean)


#### Import MIDS

mida <- read.csv('Data/MID-level-data/MIDA_4.01.csv')
midb <- read.csv('Data/MID-level-data/MIDB_4.01.csv')

mids <- merge(mida, midb, by='DispNum3') 

# recode missing day from -9 to 01
mids$StDay.y[mids$StDay.y <0] <- 1
mids$date <- as.Date(paste(mids$StYear.y, mids$StMon.y, mids$StDay.y, sep='/'))
mids$week <- as.numeric(format(as.Date(mids$date), "%U"))
mids$month <- as.numeric(format(as.Date(mids$date), "%m"))
mids$year <- as.numeric(format(as.Date(mids$date), "%Y"))

# Country selection. Select the appropriate country code and keep the same name

mids.an <- mids %>% filter(ccode == 220 & StYear.x> 1810 & StYear.y<=1914) # france

# Aggregate MIDs by month, just like the topics

mids.ag <- aggregate(data.frame(hasMid = mids.an$DispNum3), by=list(year=mids.an$StYear.y, month=mids.an$month), FUN=function(x)length(x))
mids.ag$hasMid[mids.ag$hasMid >= 2] <- 1 # make it binary


#### Merge mids.by.month with cables data

m1 <- merge(dat.ag, mids.ag, by=c('year', 'month'), all=T)
m1$hasMid[is.na(m1$hasMid)] <- 0

# remove unnecessary variables
m1$title <- m1$nmf_docid <- m1$date_time <- m1$docid <- m1$bookid <- NULL



#### Add bonds data

library(readr)
bonds_france <- read_csv("Data/Bonds_France.csv", 
                         col_types = cols(date = col_date(format = "%Y-%m-%d")))
library(lubridate)

bonds_france$date <- ymd(bonds_france$date)
bonds_france$month <- month.day.year(bonds_france$date)$month

bonds_france <- bonds_france %>% dplyr::select(year, date, month, close, cpi)

## aggregate by month 

bonds.ag <- aggregate(data.frame(bonds_france),
                      by=list(bonds_france$year, bonds_france$month), FUN=mean)


bonds.ag <- bonds.ag %>% filter(year < 1915) 
bonds.ag$Group.1 <- bonds.ag$Group.2 <- bonds.ag$Group.1 <- bonds.ag$date <- NULL


## merge everything
m1 <- merge(m1, bonds.ag, by=c('year', 'month'), all=T)

# add news 

news <- read_csv("../topic_models/output_le_figaro/newspaper_k15_dtmatrix_compact.csv", 
                 col_types = cols(date = col_date(format = "%d/%m/%Y")))

news$date <- ymd(news$date)
news$month <- month.day.year(news$date)$month
news$year <- month.day.year(news$date)$year

## rename newstopic 

news <- news %>% dplyr::rename(news_t0 = topic0, news_t1 = topic1, news_t2 = topic2, news_t3 = topic3, 
                               news_t4 = topic4, news_t4 = topic4, news_t5 = topic5, news_t6 = topic6,
                               news_t7 = topic7, news_t8 = topic8, news_t9 = topic9, news_t10 = topic10,
                               news_t11 = topic11, news_t12 = topic12, news_t13 = topic13, news_t14 = topic14)

names(news)

news.ag <- aggregate(news,
                     by=list(news$year, news$month), FUN=mean)

m1 <- merge(m1, news.ag, by=c('year', 'month'), all=T)


#### Adding some structural variables:

### National Material Capabilities (v5.0)

dat_str <- read.csv('Data/NMC_5_0.csv')
dat_str_fr <- dat_str[dat_str$ccode==220 & dat_str$year> 1810 & dat_str$year<=1914,] 

dat_str_fr[dat_str_fr == -9] <- NA # -9 recoded as NA

library(dplyr)

m1 <- m1 %>%
  left_join(dat_str_fr, by = c('year' = 'year')) 



# Trade State Level COW 4.0

dat_trade <- read.csv('Data/National_COW_4.0.csv')
dat_trade_fr <- dat_trade[dat_trade$ccode==220 & dat_trade$year> 1810 & dat_trade$year<=1914,] 

dat_trade_fr[dat_trade_fr == -9] <- NA # -9 recoded as NA

m1 <- m1 %>%
  left_join(dat_trade_fr, by = c('year' = 'year')) 


# clean up

colnames(m1)

m1 <- m1 %>% dplyr::select( -pec, -upop, - cinc, -version.x, -ccode.y, -ccode.x, -stateabb.x , -statename, -stateabb.y, -alt_imports, -alt_exports, -source1, -source2, -version.y)

m1 <- m1 %>% dplyr::rename(str_milex = milex, str_milper = milper, str_imports= imports, str_exports= exports)

m1 <- m1 %>% dplyr::rename(bonds_close = close, bonds_cpi = cpi)

m1 <- m1 %>% dplyr::rename(str_pop = tpop, str_irst=irst)



# calculate time since last mid and time to next mid
source('timeSinceEvent.R')
m1b <- m1[order(m1$year, m1$month),]
m1b$timeToCheck <- timeToEvent(m1b$hasMid)

m1 <- m1[order(m1$year, m1$month),]
m1$timeSinceMid <- NA
m1$timeToMid <- NA
m1 <- m1 %>% dplyr::rename(date = date.x)
for(ti in 1:nrow(m1)){
  listOfTimeDiffs <- m1$date[ti] - unique(mids.an$date)
  listOfPosTimeDiffs <- listOfTimeDiffs[listOfTimeDiffs > 0]
  listOfNegTimeDiffs <- listOfTimeDiffs[listOfTimeDiffs <= 0]
  m1$timeSinceMid[ti] <- min(listOfPosTimeDiffs, na.rm=TRUE)
  m1$timeToMid[ti] <- abs(max(listOfNegTimeDiffs, na.rm=TRUE))
}
m1$timeToMid[m1$timeToMid==Inf] <- NA
m1 <- m1[m1$year>=1870,]
m1 <- m1[!is.na(m1$date),]

# Add some lags and first differences for each topic
lags <- m1[, grep("topic", names(m1), value = TRUE)]
lags <- rbind(NA, lags[1:(nrow(lags)-1),])
names(lags) <- paste('l1.',names(lags), sep='')

lags_news <- m1[, grep("news", names(m1), value = TRUE)]
lags_news <- rbind(NA, lags_news[1:(nrow(lags_news)-1),])
names(lags_news) <- paste('l1.',names(lags_news), sep='')

lags_str <- m1[, grep("str", names(m1), value = TRUE)]
lags_str <- rbind(NA, lags_str[1:(nrow(lags_str)-1),])
names(lags_str) <- paste('l1.',names(lags_str), sep='')


lags_bonds <- m1[, grep("bonds", names(m1), value = TRUE)]
lags_bonds <- rbind(NA, lags_bonds[1:(nrow(lags_bonds)-1),])
names(lags_bonds) <- paste('l1.',names(lags_bonds), sep='')


m1 <- cbind(m1, lags)
m1 <- cbind(m1, lags_str)
m1 <- cbind(m1, lags_bonds)
m1 <- cbind(m1, lags_news)


# Add bonds returns, instead of using the raw value only
m1$r1.bonds_close <- (m1$bonds_close - m1$l1.bonds_close) / m1$l1.bonds_close
m1$lr1.bonds_close <- log(1+m1$r1.bonds_close)

# add first differences 
diffs <- diff(as.matrix(m1[,grep("topic", names(m1), value = TRUE)]))
diffs <- as.data.frame(rbind(NA, diffs))
names(diffs) <- paste('d1.',names(diffs), sep='')
m1 <- cbind(m1, diffs)


m1$hasMidWithin12 <- 0 
m1$hasMidWithin12[m1$timeToMid < 365] <- 1


m1$l1.str_milex <-  m1$l1.str_milex/100
m1$l1.str_milper <-  m1$l1.str_milper/100
m1$l1.str_imports <-  m1$l1.str_imports/100
m1$l1.str_exports <-  m1$l1.str_exports/100
m1$l1.str_pop <-  m1$l1.str_pop/100
m1$l1.str_irst <-  m1$l1.str_irst/100


write.csv(m1, 'Data/preppedPredictionData.csv')
