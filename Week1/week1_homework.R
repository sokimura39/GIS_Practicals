library(sf)
library(tmap)
library(tmaptools)
library(RSQLite)
library(tidyverse)

#read shp
shape <- st_read("Data/Homework/Territorial_Authority/territorial-authority-2018-generalised.shp")

#csv
mycsv <- read_csv("Data/Homework/Dataset/NZ_employment2018.csv")

mycsv

#merge
shape2 <- shape %>%
  merge(.,
        mycsv,
        by.x="TA2018_V1_",
        by.y="Area_Code")

shape_simple <- st_simplify(shape2, dTolerance = 1000)

# #show map
tmap_mode("plot")
# qtm(shape2, fill = "Paid employee")

tm_shape(shape2) + tm_fill("Paid employee", style = "quantile", palette = "Greens") + tm_borders()

#gpkg
shape2 %>%
  st_write(.,
           "Data/Homework/Dataset/NZemployment.gpkg",
           delete_layer = TRUE)

con <- dbConnect(SQLite(),
                 dbname = "Data/Homework/Dataset/NZemployment.gpkg")

con %>%
  dbWriteTable(.,
               "original_csv",
               mycsv,
               overwrite = TRUE)

con %>%
  dbListTables()

con %>%
  dbDisconnect()


  
