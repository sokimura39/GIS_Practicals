library(tidyverse)
library(dplyr)
library(janitor)
library(plotly)
library(maptools)
library(RColorBrewer)
library(classInt)
library(sp)
library(rgeos)
library(tmap)
library(tmaptools)
library(sf)
library(rgdal)
library(geojsonio)
library(OpenStreetMap)

Data1 <- c(1:100)
Data2 <- c(101:200)

plot(Data1, Data2, col="red")

Data3 <- rnorm(100, mean = 53, sd = 34)
Data4 <- rnorm(100, mean = 64, sd = 17)

plot(Data3, Data4, col="blue")

df <- data.frame(Data1, Data2)
plot(df, col = "green")

df %>%
  head()

tail(df)

df[1:10, 1]
df[5:15, ]
df[c(2,3,6),2]
df[,2]

df <- df %>%
  dplyr::rename(column1 = Data1, column2=Data2)

df %>%
  dplyr::select(column1)

df$column1
df[["column1"]]


LondonDataOSK <- read.csv("Data/LondonData.csv",
                          header = TRUE,
                          sep = ",",
                          encoding = "latin1")


Datatypelist <- LondonDataOSK %>%
  summarise_all(class) %>%
  pivot_longer(everything(),
               names_to = "All_variables",
               values_to = "Variable_class")

Datatypelist

LondonDataOSK %>%
  colnames() %>%
  head()

LondonBoroughs <- LondonDataOSK %>%
  # ^: starts with
  filter(str_detect(`New.code`, "^E09"))

LondonBoroughs$Ward.name

LondonBoroughs <- LondonBoroughs %>%
  distinct()

LondonBoroughs <- LondonBoroughs %>%
  dplyr::rename(Borough="Ward.name") %>%
  clean_names()

Life_expectancy <- LondonBoroughs %>%
  # new column with average of male and female life expectancy
  mutate(average_life_expectancy = 
           (female_life_expectancy_2009_13 + 
              male_life_expectancy_2009_13) / 2) %>%
  # new column with normalised life expectancy
  mutate(normalised_life_expectancy = 
           (average_life_expectancy / 
              mean(average_life_expectancy))) %>%
  #select columns
  dplyr::select(new_code,
                borough,
                average_life_expectancy,
                normalised_life_expectancy) %>%
  #descending order
  arrange(desc(normalised_life_expectancy))

# slice_head(Life_expectancy, n = 5)

Life_expectancy2 <- Life_expectancy %>%
  mutate(UKcompare = case_when(average_life_expectancy > 81.16 ~ "above UK average",
                               TRUE ~ "below UK average"))

Life_expectancy2_group <- Life_expectancy2 %>%
  mutate(UKdiff = average_life_expectancy - 81.16) %>%
  group_by(UKcompare) %>%
  summarise(range=max(UKdiff)-min(UKdiff), count=n(), Average=mean(UKdiff))

Life_expectancy3 <- Life_expectancy2 %>%
  mutate(UKdiff = average_life_expectancy - 81.16) %>%
  mutate(across(where(is.numeric), round, 3)) %>%
  mutate(across(UKdiff, round, 0)) %>%
  mutate(UKcompare = case_when(average_life_expectancy >= 81 ~ 
                                 str_c("Equal or above UK average by", UKdiff, "years", sep = " "),
                               TRUE ~ 
                                 str_c("Below UK average by", UKdiff, "years", sep = " "))) %>%
  group_by(UKcompare) %>%
  summarise(count=n())

Life_expectancy4 <- Life_expectancy2 %>%
  mutate(UKdiff = average_life_expectancy - 81.16) %>%
  mutate(across(where(is.numeric), round, 3)) %>%
  mutate(across(UKdiff, round, 0))

# plot(LondonBoroughs$male_life_expectancy_2009_13, LondonBoroughs$x_children_in_reception_year_who_are_obese_2011_12_to_2013_14)

# plot_ly(LondonBoroughs,
#        # data
#        x = ~male_life_expectancy_2009_13,
#        y = ~x_children_in_reception_year_who_are_obese_2011_12_to_2013_14,
#        # attribute to display when hovering
#        text = ~borough,
#        type = "scatter",
#        mode = "markers")

EW <- st_read("Data/Local_Authority_Districts_Boundaries/Local_Authority_Districts_(December_2015)_Boundaries.shp")
LondonMap <- EW %>%
  filter(str_detect(lad15cd, "^E09"))

# show map
# qtm(LondonMap)

# using merge - never again!
BoroughDataMap <- EW %>%
  clean_names(.) %>%
  filter(str_detect(lad15cd, "^E09")) %>%
  merge(.,
        LondonDataOSK,
        by.x = "lad15cd",
        by.y = "New.code",
        no.dups = TRUE) %>%
  distinct(., lad15cd, .keep_all = TRUE)

# Use left_join()
BoroughDataMap2 <- EW %>%
  clean_names(.) %>%
  filter(str_detect(lad15cd, "^E09")) %>%
  left_join(.,
            LondonDataOSK,
            by = c("lad15cd" = "New.code"))

BoroughDataMap2 <- BoroughDataMap2 %>%
  distinct(.)
  
tmap_mode("plot")
# qtm(BoroughDataMap2,
#     fill = "Rate.of.All.Ambulance.Incidents.per.1.000.population...2014")

tmaplondon <- BoroughDataMap2 %>%
  st_bbox(.) %>%
  tmaptools::read_osm(., type = "osm", zoom = NULL)

# 
# tm_shape(tmaplondon) +
#   tm_rgb() +
#   tm_shape(BoroughDataMap2) +
#   tm_polygons("Rate.of.All.Ambulance.Incidents.per.1.000.population...2014",
#               style = "jenks",
#               palette = "YlOrBr",
#               midpoint = NA,
#               title = "Rate per 1,000 people",
#               alpha = 0.5) +
#   tm_compass(position = c("left", "bottom"),
#              type = "arrow",) +
#   tm_scale_bar(position = c("left", "bottom")) +
#   tm_layout(title = "Ambulance Incidents", legend.position = c("right","bottom"))



Life_expectancy4map <- EW %>%
  inner_join(.,
             Life_expectancy4,
             by = c("lad15cd" = "new_code")) %>%
  distinct(., lad15cd, .keep_all = TRUE)

tm_shape(tmaplondon) + 
  tm_rgb() +
  tm_shape(Life_expectancy4map) + 
  tm_polygons("UKdiff",
             style = "pretty",
             palette = "Blues",
             midpoint = NA,
             title = "Number of Years",
             alpha = 0.5) +
  tm_compass(position = c("left","bottom"),type = "arrow") +
  tm_scale_bar(position = c("left","bottom")) + 
  tm_layout(title = "Difference in life expectancy",legend.position = c("right","bottom"))

flytipping <- read_csv("C:/Users/Soki/OneDrive - University College London/01_Courses/CASA0005_GIS/Data/Week1/London/fly-tipping-borough.csv",
                      col_types = cols(
                        code = col_character(),
                        area = col_character(),
                        year = col_character(),
                        total_incidents = col_number(),
                        total_action_taken = col_number(),
                        warning_letters = col_number(),
                        fixed_penalty_notices = col_number(),
                        statutory_notices = col_number(),
                        formal_cautions = col_number(),
                        injunctions = col_number(),
                        prosecutions = col_number()
                      ))

view(flytipping)

flytipping_long <- flytipping %>%
  pivot_longer(
    cols = 4:11,
    names_to = "tipping_type",
    values_to = "count"
  )
view(flytipping_long)

flytipping_wide <- flytipping_long %>%
  pivot_wider(
    id_cols = 1:2,
    names_from = (c(year,tipping_type)),
    names_sep = "_",
    values_from = count
  )

view(flytipping_wide)