library(shiny)
library(leaflet)
library(ggiraph)

shinyUI(fluidPage(
  
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
)
