library(sf)
library(tmap)
library(tmaptools)
library(RSQLite)
library(tidyverse)


# read in the shapefile
shape <- st_read("Data/London/statistical-gis-boundaries-london/ESRI/London_Borough_Excluding_MHW.shp")

#read in the csv
mycsv <- read_csv("Data/London/pivot_fly_tipping_borough.csv")

#merge csv and shapefile
shape2 <- merge(shape,
        mycsv,
        by.x="GSS_CODE",
        by.y="label")

#set tmap to plot
tmap_mode("plot")

#look at map
qtm(shape2, fill = "2011-12")

#write to a .gpkg
shape %>%
  st_write(., 
           "Data/London/flytipping_R.gpkg", 
           "london_boroughs_fly_tipping", 
           delete_layer=TRUE)

#connect to .gpkg

con <- dbConnect(SQLite(),
                 dbname="Data/London/flytipping_R.gpkg", "london_boroughs_fly_tipping")

#list
con %>%
  dbListTables()

#add original csv
con %>%
  dbWriteTable(.,
               "original_csv",
               mycsv,
               overwrite="TRUE")

#disconnect from .gpkg
con %>%
  dbDisconnnect()




  