library(shiny)
library(ggplot2)
library(tidyverse)
library(urbnmapr)
library(here)
library(usmap)
library(leaflet)
library(sf)
library(ggiraph)
library(htmltools)

data <- read.csv("data_2023.csv")
autocomplist <- data$species
specnat <- read.csv(here("specnat.csv"))
sta <- read.csv(here("states.csv"))

shinyServer(function(input, output, session) {
  
  # for autofill list; put on server side to load app faster 
  updateSelectizeInput(session, "sp", choices = autocomplist, selected=character(0), server = TRUE)
  
  # filter data for species selected in the UI 
  selected <- reactive(data %>% filter(species == input$sp))
  
  # Table for specimen total count by specimen type
  output$specnat <- renderTable(
    selected() %>% count(Description)
  )
  
  # from the selected data, filter out skels and skins
  data_filt <- reactive({
    selected() %>% 
      filter(nat == "skeleton" | nat == "study skin")
  })
  
  output$trend <- renderPlot({
    data_filt() %>% 
      ggplot(aes(x = year, fill = nat, color = nat)) +
      geom_bar(position = position_dodge(preserve = "single")) +
      scale_x_continuous(breaks = seq(1880, 2020, 10)) +
      xlim(1850, 2023) +
      theme_classic() +
      labs(fill = "Specimen type", color = "Specimen type", x = "Year", y = "Count")
    
  }, res = 96)
  
  output$countbyyear <- renderTable(
    selected() %>% count(year)
  )
  
  output$summary <- renderTable(
    selected() %>% count(year, specnat)
  )
  
  output$specnat <- renderTable(
    selected() %>% count(Description)
  )
  
  # count by month and type
  output$trend2 <- renderPlot({
    data_filt() %>% 
      ggplot(aes(x = month, fill = nat, color = nat)) +
      geom_bar(position = position_dodge(preserve = "single")) +
      scale_x_continuous(breaks = seq(1, 12, 1), labels = c("Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec")) +
      theme_classic() +
      labs(fill = "Specimen type", color = "Specimen type", x = "Month", y = "Count")
    
  }, res = 96)  
  
  spat_state1 <- reactive({
    left_join(get_urbn_map(map = "states", sf = TRUE),
              selected() %>% 
                count(abv),
              by = c("state_abbv" = "abv"))
  })
  
  # app format  
  output$state <- renderPlot({
    spat_state1() %>% 
      ggplot() +
      geom_sf(spat_state1(),
              mapping = aes(fill = n),
              color = "#ffffff", size = 0.25) +
      labs(fill = "Specimen count") +
      scale_fill_viridis_c(option = "D")  
  })
  
  # reactive map by county 
  # within California only  
  spat_ca_cty <- reactive({
    left_join(get_urbn_map(map = "counties", sf = TRUE) %>% 
                filter(state_abbv == "CA"),
              selected() %>% 
                count(cty2),
              by=c("county_name"="cty2")) 
  })
  
  
  # app format  
  output$ca_cty <- renderPlot({
    spat_ca_cty () %>% 
      ggplot() +
      geom_sf(spat_ca_cty(),
              mapping = aes(fill = n),
              color = "#ffffff", size = 0.25) +
      labs(fill = "Specimen count") +
      scale_fill_viridis_c(option = "D")  
  })
  
  # leaflet map
  # filter data for map data
  map_df <- reactive({
    selected() %>% 
      filter(!is.na(lng) & !is.na(lat)) %>% 
      st_as_sf(coords = c("lng", "lat"))
  })
  
  # actual map
  output$map = renderLeaflet({
    leaflet() %>%
      addTiles() %>%
      addCircleMarkers(data = map_df(), radius=1) 
  })  
  
  # boxplot with weights split by sex
  # with ggiraph for interactive plot 
  
  # points that will be selected in the interactive plot
  selected_pts <- reactive({
    input$wtPlot_selected
  })
  
  # hovered points 
  output$console <- renderPrint({
    input$wtPlot_hovered
  })
  
  # interactive plot
  output$wtPlot <- renderGirafe({
    gg_bx <- ggplot(selected(), aes(x=sex, y=wt)) +
      stat_boxplot(geom="errorbar", position="dodge2") +
      geom_boxplot(stat="boxplot", position="dodge2", outlier.shape = NA) +
      geom_point_interactive(aes(tooltip=lacm, data_id=lacm),
                             size=3, hover_nearest=T, position=position_jitter(0.2))  +
      scale_x_discrete(limits = c("M", "F", "U"), labels = c("Male", "Female", "Unknown")) +
      labs(x = "Sex", y = "Weight (g)")
    girafe(ggobj = gg_bx)
  })
  
  # table of all the selected points from the interactive plot
  output$datatab <- renderTable({
    out <- selected()[selected()$lacm %in% selected_pts(),] %>% 
      mutate(LACM = lacm, LAF = laf, Sex = sex, subspecies = spp, Date = datecoll, Locality = locality, SpecType = nat) %>% 
      select(LACM, LAF, Sex, subspecies, Date, Locality, SpecType) 
    if( nrow(out) < 1 ) return(NULL)
    row.names(out) <- NULL
    out
  })
  
  
  # Table for specimen count by year
  output$countbyyear <- renderTable(
    selected() %>% count(year)
  )
  
  # Table for specimen count by year by specimen type
  output$summary <- renderTable(
    selected() %>% count(year, specnat)
  )
  
  
  ##### Tab 2
  # new filter based on catalog number (LACM)
  selected2 <- reactive(data %>% filter(lacm == input$catalog)) 
  
  # table listing all relevant field information 
  output$catcount <- renderTable(
    selected2() %>% 
      mutate(
        LACM = lacm,
        LAF = laf,
        Family = family,
        Species = species,
        Subspecies = spp,
        Sex = sex,
        Date = datecoll,
        Locality = locality
      ) %>% 
      select(LACM, LAF, Family, Species, Subspecies, Sex, Date, Description, Locality)
  )
  
  ###
  # leaflet map of locality
  # set up filtered data, remove any NA values (will not plot)
  catmap_df <- reactive({
    selected2() %>% 
      filter(!is.na(lng) & !is.na(lat)) %>% 
      st_as_sf(coords = c("lng", "lat"))
  })
  
  # set up leaflet map 
  output$catmap = renderLeaflet({
    leaflet() %>%
      addTiles() %>%
      addCircleMarkers(data = catmap_df(), radius=1, 
                       popup=paste("LACM ", catmap_df()$lacm, "<br>", catmap_df()$datecoll, sep = " "))
  })
  
})
