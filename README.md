# Collections Data

As collections managers, we want to make our collection data are easily accessible, not just for us daily users but to all visitors and interested researchers. In addition, with endless incoming specimens and limited collections space, we want to ensure that our collection grows in a way that maximizes intraspecific variation and collections use for researchers. In other words, I want to be able to make a quick decision on what specimen preparation type would work for this next specimen I'm about to prepare. 

This [shiny](https://shiny.posit.co/) application provides a quick visualized summary of the specimen data for a collection that allows users to interpret and assess specimen information for various goals. As long as the data is formatted correctly, you should be able to have your very own app that can be used to access your collections data. Check out this [LACM example](https://nhm-birds.shinyapps.io/lacm_birds/) to see what the script can do. I have this as a bookmark on my phone to quickly check what specimen types are lacking for an incoming specimen, or lookup relevant information from just catalog numbers. 


![app_preview](https://github.com/younghasuh/collectionsdata/assets/22403928/3667a03b-a543-4a05-aa96-7649bd71306f)


## App overview
### Species summary tab
Provides an overview on how specimens are available by specimen type/nature based on species. Once you start typing in the blank field it should list options that you can select from. If you cannot find a species, it is likely that there are no specimens of that kind or you are searching with an updated scientific name that is different from the database. 

1. **Specimen count by specimen type**
Lists all the different specimen types for the input species. Description is written out in depth based on the specimen nature codes and their descriptions in EMu.

2. **Specimen count by year**
The count of specimens for each year based only on study skins and skeletons; rest are ignored for visualization purposes. 

3. **Specimen count by month**
The count of specimens by the month they were collected. 

4. **Specimen count by state**
A map showing the number of specimens collected in each state. Given the nature of the locality data, the map is only limited to the United States. Higher values are in yellow while lower values are in dark purple. States where we have no specimens are grayed out. Note, this map is generated with only georeferenced data.

5. **Specimen count by county**
A map showing the number of specimens collected in each county of California. Given the nature of the locality data, the map is only limited to California. Higher values are in yellow while lower values are in dark purple. Counties where we have no specimens are grayed out. Note, this map is generated with only georeferenced data. 

6. **Global specimen distribution**
An interactive map (Feaflet) showing the global distribution of specimen localities. Adjust the zoom using the +/- sign on the top left corner of the map. Note, this map is generated with only georeferenced data. 

7. **Weights by sex**
Simple box plots of each specimen’s weight based on sex (male, female, unknown). Raw data points are scattered over the box plots.   

8. **Detailed counts by year**
Last is a long table including the counts of specimens by year and counts by year and type. 


![app_preview2](https://github.com/younghasuh/collectionsdata/assets/22403928/cbfc9ef7-519a-46ed-a4bd-2731aea3cd74)

## LACM lookup
For looking up specimens based on LACM number. It will provide information on species, collection date, collector, and locality. There are a few instances where you will enter a number but have no results; this is likely that there is missing information on the specimen. This is a feature that will be fixed in the next update. 


## Running the app in R Studio


## Publishing the app 
If you want your app to be available on the web, you will need to deploy it on your server or on a hosting service. The LACM app is hosted through shinyapps.io and instructions can be found [here](https://shiny.posit.co/r/articles/share/shinyapps/). Note that in order to use shinyapps.io, you need to split the `app.R` file into two: `UI.R` and `server.R`. This repo contains both for reference. 
More information on deployment be found [here](https://shiny.posit.co/r/deploy.html).
