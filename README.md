# Collections Data

As collections managers, we want to make our collection data are easily accessible, not just for us daily users but to all visitors and interested researchers. In addition, with endless incoming specimens and limited collections space, we want to ensure that our collection grows in a way that maximizes intraspecific variation and collections use for researchers. In other words, I want to be able to make a quick decision on what specimen preparation type would work for this next specimen I'm about to prepare. 

This [shiny](https://shiny.posit.co/) application provides a quick visualized summary of the specimen data for a collection that allows users to interpret and assess specimen information for various goals. As long as the data is formatted correctly, you should be able to have your very own app that can be used to access your collections data. Check out this [LACM example](https://nhm-birds.shinyapps.io/lacm_birds/) to see what the script can do. I have this as a bookmark on my phone to quickly check what specimen types are lacking for an incoming specimen, or lookup relevant information from just catalog numbers. 


![app_preview](https://github.com/younghasuh/collectionsdata/assets/22403928/3667a03b-a543-4a05-aa96-7649bd71306f)


## App overview


## Running the app in R Studio


## Publishing the app 
If you want your app to be available on the web, you will need to deploy it on your server or on a hosting service. The LACM app is hosted through shinyapps.io and instructions can be found [here](https://shiny.posit.co/r/articles/share/shinyapps/). Note that in order to use shinyapps.io, you need to split the `app.R` file into two: `UI.R` and `server.R`. This repo contains both for reference. 
More information on deployment be found [here](https://shiny.posit.co/r/deploy.html).
