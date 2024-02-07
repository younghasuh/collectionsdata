# Load libraries
library(here)
library(shiny)
library(ggplot2)
library(tidyverse)
library(urbnmapr)
library(usmap)
library(leaflet)
library(sf)
library(ggiraph)

# set working directory
here::i_am("app.R")

# Load data
data <- read.csv("data_2023.csv")

# List of species names for autofill field
autocomplist <- data$species

# Load additional tidying data sets
specnat <- read.csv(here("specnat.csv"))
sta <- read.csv(here("states.csv"))

#####
# Set UI (user interface)

ui <- fluidPage(
  
  # title of the app, including a logo image
  titlePanel(title =  div(img(src="NHM_logo_black_250.png", 
                              width="50px", height="50px"), 
                          "LACM Specimen trends and maps")),
  # panel with tabs 
  mainPanel(
    tabsetPanel(
      type = "tabs",
      
      ###
      # tab 1
      tabPanel(
        titlePanel("Species summary"),
        
        # using panel with side bar
        sidebarLayout(
          
          # set up side bar panel
          sidebarPanel(
            h2("Species"),
            p("Start typing species and select from drop-down list."),
            
            selectizeInput(
              inputId = 'sp',
              label = 'Species',
              choices = NULL,
              selected = NULL,
              multiple = FALSE, # allow for multiple inputs
              options = NULL),
            
            fluidRow(column(12, h4("Specimen count by specimen type/nature"), tableOutput("specnat")))
          ),
          
          # set up main panel 
          mainPanel(
            
            fluidRow(column(12, h4("Specimen count by year"), plotOutput("trend"))),
            
            fluidRow(column(12, h4("Specimen count by month"), plotOutput("trend2"))),
            
            fluidRow(column(12, h4("Specimen count by state (US only)"), plotOutput("state"))),
            
            fluidRow(column(12, h4("Specimen count by county (CA only)"), plotOutput("ca_cty"))),
            
            fluidRow(column(12, h4("Global specimen distribution"), leafletOutput(outputId = 'map'))),
            
            fluidRow(column(8, h4("Weights by sex - interactive"), girafeOutput("wtPlot2")),
                     column(4, h4("Hovering points"), verbatimTextOutput("console"),
                            h4("Selected points"), tableOutput("datatab"))),
            
            
            fluidRow(h4("Detailed counts by year"),
                     column(2, tableOutput("countbyyear")),
                     column(3, tableOutput("summary")))
          )
        )),
      
      ###
      # tab 2
      # only using single panel
      tabPanel(
        titlePanel("LACM lookup"),
        textInput("catalog", "LACM"),
        fluidRow(column(12, tableOutput("catcount"))),
        fluidRow(column(12, h4("Leaftlet map"), leafletOutput(outputId = 'catmap')))
      )
      
    )))


#####
# Define server
server <- function(input, output, session) {
  
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
  
}


#####
# Run app 
shinyApp(ui = ui, server = server)
