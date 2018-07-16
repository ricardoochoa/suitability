# Suitability 
# server.R

shinyServer(function(input, output, session) {
  
  settings_dataframe <- reactive({
    if(is.null(input$settings_table)){
      return(read_csv(paste0("_data/",
                      input$select_data,
                      "/settings/settings.csv"), 
                      col_types = cols(normalization_method = col_factor(levels = c("observe", "reference", "standardize")), 
                                       smaller_better = col_logical(), 
                                       default_on = col_logical())))
    } else {
      return(hot_to_r(input$settings_table))
    }
  })
  
  # Filters checkbox group
  output$filter_checkboxgroup <- renderUI({
    
    checkboxGroupInput("selected_filter_names", label = h3("Filters"),
                       choices = as.list(read_csv(paste0("_data/",
                                                 input$select_data,
                                                 "/settings/filter_names.csv"))$filter)
                         )
  })
  
  # Layers checkbox group
  output$layer_checkboxgroup <- renderUI({
    
    temp_df <- read_csv(paste0("_data/", input$select_data, "/settings/settings.csv"))
    all_layers <- as.list(temp_df$layer)
    default_on <- as.list(temp_df[which(temp_df$default_on == TRUE),]$layer)
    
    checkboxGroupInput("selected_layer_names", 
                       label = h4("Select layers:"),
                       choices = all_layers, 
                       selected = default_on
    )
  })
    
  names_dataframe <- reactive({
    read_csv(paste0("_data/",
                    input$select_data,
                    "/settings/layer_names.csv"))
  })
  
  output$settings_table <- renderRHandsontable({
    rhandsontable(settings_dataframe(), rowHeaders = NULL) %>%
      hot_col(col = "layer", readOnly = TRUE) %>%
      hot_col(col = "default_on", readOnly = TRUE) %>%
      hot_col(col = "normalization_method", type = "dropdown", source = c("observe", "reference", "standardize")) %>%
      hot_col(col = "smaller_better", type = "checkbox", source = c("TRUE", "FALSE")) %>%
      hot_col(col = "default_on", type = "checkbox", source = c("TRUE", "FALSE"))
  })
    
  selected_layers <- reactive({
    merge(x = settings_dataframe(), y = data.frame(layer = input$selected_layer_names))
  })
  
  selected_filters <- reactive({
    if(length(input$selected_filter_names) == 0){
      return(1)} else {
      filter_dataframe <- read_csv(paste0("_data/", input$select_data, "/settings/filter_names.csv"))
      selected_filter_files <- paste0("_data/",
                                      input$select_data, 
                                      "/filters/", 
                                      merge(x = filter_dataframe, 
                                            y = data.frame(filter = input$selected_filter_names))[,"preprocessed_raster"])
      selected_filter_rasters <- lapply(X = selected_filter_files, FUN = raster)
      if(length(input$selected_filter_names) == 1){
        the_filter <- selected_filter_rasters[[1]]
        if(as.numeric(input$fact) != 1){
        # 0.92
        the_filter <- aggregate(x = the_filter, fact = as.numeric(input$fact), fun = max, na.rm = TRUE)
        }
        the_filter[the_filter < 1] <- NA
        return(the_filter)} else {
          if(as.numeric(input$fact) != 1){
            selected_filter_rasters = lapply(X = selected_filter_rasters,
                                             FUN = aggregate,
                                             fact = as.numeric(input$fact), 
                                             fun = max, 
                                             na.rm = TRUE)
            }
          selected_filter_stack <- stack(selected_filter_rasters)
        the_filter <- grind_r(filter_stack = selected_filter_stack, 
                              operation = input$selected_filter_operation)
        return(the_filter)
      }  
    }
  })
  
  results_tabular <- reactive({
    merge(x = names_dataframe(), y = selected_layers())
  })
  
  results_spatial <- reactive({
    
    something_went_wrong <- raster(matrix(data = rep(NA, 10), nrow = 1, ncol = 10)) # raster1
    extent(something_went_wrong) <- c(-90, 90, -40, 40)
    projection(something_went_wrong) <- CRS("+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs")
    
    result = tryCatch({
      get_spatial_results(names_dataframe = names_dataframe(), 
                          selected_layers = selected_layers(), 
                          path = paste0("_data/",
                                        input$select_data,
                                        "/layers/"), 
                          filter_raster = selected_filters(), 
                          fact = as.numeric(input$fact))
    }, warning = function(w) {
      something_went_wrong
    }, error = function(e) {
      something_went_wrong
    }, finally = {
      # do nothing
    }
  )
  })
  
  # map
  output$map <- renderLeaflet({
    
    indexed_raster <- results_spatial()
    
    if(all(is.na(indexed_raster[]))){
      
      showNotification("trying to find something to map...")
      
      leaflet() %>% 
        addProviderTiles(input$map_type) %>%
        addRasterImage(indexed_raster)
      
    } else {

      indexed_raster[indexed_raster < input$subset_score[1]] <- NA
      indexed_raster[indexed_raster > input$subset_score[2]] <- NA
      
      leaflet() %>% 
        addProviderTiles(input$map_type) %>% 
        addRasterImage(indexed_raster, 
                       colors = pal,
                       opacity = as.numeric(input$transparency)) %>%
        addLegend(pal = pal, 
                  values = 0:100, 
                  title = "Index", 
                  position = "bottomright")
    }
    
  })
  
  # plot
  output$plot <- renderPlot({
    
    indexed_raster <- results_spatial()
    
    if(all(is.na(indexed_raster[]))){
      g <- ggplot()
    } else {
      i = indexed_raster[]
      i = i[!is.na(i)]
      waffle_plot(i = i)
    }
  })
  
  output$read_me_text <- renderUI({
    includeMarkdown(paste0("_data/",
                           input$select_data,
                           "/read_me.md"))
  })
  
  output$data_tab_select_layers = renderUI({
    all_layers = 
            tryCatch(
              expr = read_csv(paste0("_data/", input$select_data, "/settings/layer_names.csv"))$layer, 
              error = function(e){return("Loading...")}, 
              warning = function(w){return("Loading...")})

    selectInput('data_tab_selected_layer', 'Select layer', as.list(all_layers))
  })
  
  output$data_tab_description = renderText({
    
    the_text = 
      tryCatch(as.character(read.csv(file = paste0("_data/",
                                                 input$select_data, 
                                                 "/settings/layer_names.csv"),
                                   row.names = 1)[input$data_tab_selected_layer, 
                                                  "description"]), 
             error = function(e){return("Loading...")}, 
             warning = function(w){return("Loading...")})

    the_text  
    
  })
  
  # data tab map
  output$data_tab_map <- renderPlot({

    the_raster = tryCatch(
      expr = {
      raster(paste0("_data/",
                    input$select_data,
                    "/layers/",
                    as.character(read.csv(file = paste0("_data/",
                                                        input$select_data,
                                                        "/settings/layer_names.csv"),
                                          row.names = 1)[input$data_tab_selected_layer, "preprocessed_raster"])))
    }, warning = function(w) {
      something_went_wrong()
    }, error = function(e) {
      something_went_wrong()
    }, finally = {
      # do nothing
    }, 
    message = "Loading...")
    
      try(levelplot(the_raster))
    
  })  
  
  output$download_indexed_tif <- downloadHandler(  
    
    filename = function() {
        paste('Suitability_', Sys.Date(), '.tif', sep='')
      },
      content = function(file) {
        
        indexed_raster <- results_spatial()
        
        indexed_raster[indexed_raster < input$subset_score[1]] <- NA
        indexed_raster[indexed_raster > input$subset_score[2]] <- NA
        
        writeRaster(x = indexed_raster, file)
      }
    )
  
  output$download_indexed_pdf <- downloadHandler(  
    
    filename = function() {
      paste('Suitability_', Sys.Date(), '.pdf', sep='')
    },
    content = function(file) {
      my_theme <- rasterTheme(region = c("#C44D58", 
                                         "#FF6B6B", 
                                         "#C7F464", 
                                         "#4ECDC4", 
                                         "#556270"))
      
      pdf(file)
        print(
          levelplot(results_spatial(), par.settings = my_theme)
          )
      dev.off()
    }
  )
  
  output$download_indexed_png <- downloadHandler(  
    
    filename = function() {
      paste('Suitability_', Sys.Date(), '.png', sep='')
    },
    content = function(file) {
      my_theme <- rasterTheme(region = c("#C44D58", 
                                         "#FF6B6B", 
                                         "#C7F464", 
                                         "#4ECDC4", 
                                         "#556270"))
      
      png(file)
      print(
        levelplot(results_spatial(), par.settings = my_theme)
      )
      dev.off()
    }
  )
  
  observeEvent(eventExpr = input$select_data,
               handlerExpr = {
                 updateCheckboxGroupInput(session, "selected_filter_names",
                                          label = h3("Filters"),
                                          choices = as.list(read_csv(paste0("_data/",
                                                                            input$select_data,
                                                                            "/settings/filter_names.csv"))$filter)
                 )
                 
  })
  
})


