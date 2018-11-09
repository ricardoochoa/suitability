# Suitability 
# ui.R

navbarPage(title=div(img(src="logo.svg", align="center")), 
  windowTitle="Suitability",
           selected = "Tool", 
           # ------- WELCOME
           tabPanel("Welcome", 
                    includeMarkdown("_md/welcome.md"), 
                    hr(), footer), 
           # ------- TOOL
           tabPanel("Tool",
                    fluidPage(
                      fluidRow(
                        column(8,
                               tags$style(type = "text/css", "#map {height: calc(100vh - 120px) !important;}"),
                               leafletOutput("map"), 
                               downloadButton("download_indexed_pdf", "PDF"),
                               downloadButton("download_indexed_png", "PNG"),
                               downloadButton("download_indexed_tif", "TIF")
                        ),
                        column(4,
                               tabsetPanel(id = "tabs",
                                           tabPanel(title = "Layers", value = "panel1", 
                                                    selectInput("select_data", label = h4("Select a city:"),
                                                                choices = list.files(data_folder)),
                                                    selectInput("fact", 
                                                                label = h4("Select resolution:"),
                                                                              choices = list("High" = 1,
                                                                                             "Mid"  = 10,
                                                                                             "Low"  = 20),
                                                                              selected = 20),
                                                    # uiOutput("resolution_select"),
                                                    uiOutput("layer_checkboxgroup"),
                                                    plotOutput('plot', width = "300px", height = "250px"), 
                                                    p("The Graphical Summary shows a square pie-chart with the proportion of Index values in the selected area.")),
                                           tabPanel(title = "Filters", value = "panel2", 
                                                    uiOutput("filter_checkboxgroup"), 
                                                    selectInput("selected_filter_operation", label = h4("Operation"), 
                                                                choices = c("Union" = "union", 
                                                                            "Intersection" = "intersection", 
                                                                            "Difference" = "difference"))),
                                           tabPanel(title = "Aesthetics", value = "panel3", 
                                                    selectInput("map_type", label = "Map type", 
                                                                choices = list("Hydda" = "Hydda.Full", 
                                                                               "OSM (black & white)" = "OpenStreetMap.BlackAndWhite", 
                                                                               "OSM Mapnik" = "OpenStreetMap.Mapnik", 
                                                                               "Satellite" = "Esri.WorldImagery", 
                                                                               "Stamen Watercolor" = "Stamen.Watercolor", 
                                                                               "Stamen TonerLite" = "Stamen.TonerLite"),
                                                                selected = "OpenStreetMap.BlackAndWhite"), 
                                                    # Select point size
                                                    sliderInput("transparency", "Transparency",
                                                                min = 0, max = 1, value = 0.75), 
                                                    # Subset by score
                                                    sliderInput("subset_score", "Subset by score",
                                                                min = 0, max = 100, value = c(0,100)))
                               )

                                 )
                               )
                        ), 
                    hr(), footer
                        ),
           # ------- SETTINGS            
           tabPanel("Settings", 
                    h1("Settings"), 
                    p("Modify the following table to update normalization methods and weighting values. Please note that changes will affect only selected layers. Read below for fourther information regarding columns in the table."), 
                    rHandsontableOutput(outputId = "settings_table"), 
                    hr(),
                    includeMarkdown("_md/settings.md"), 
                    hr(), footer
                    
           ), 
           # ------- DATA
           tabPanel("Data", 
                    includeMarkdown("_md/data.md"),
                    uiOutput("read_me_text"), 
                    uiOutput('data_tab_select_layers'), 
                    textOutput("data_tab_description"),
                    br(),
                    plotOutput("data_tab_map"),
                    hr(), footer), 
           
           # ------- TECHNICAL
           # tabPanel("Technical", 
           #          includeMarkdown("_md/technical.md"), 
           #          hr(), footer), 
           
           # ------- ABOUT
           tabPanel("About CPL", 
                    includeMarkdown("_md/about.md"), 
                    hr(), footer)
           )
