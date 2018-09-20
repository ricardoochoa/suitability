# Suitability 
# functions.R

scale_r <- function(R, selected_method = "observe", MIN = NULL, MAX = NULL ){
  # internal function: normalize a raster based on min and max values
  normalize_r <- function(R, MIN, MAX){
    # let the smallest value be zero
    R <- R - MIN
    # let any number smaller than zero be zero
    R[R <= 0] <- 0
    # let the largest value be 100
    R <- 100*R/(MAX-MIN)
    # let any number larger than 100 be 100
    R[R >= 100] <- 100
    return(R)
  }
  # scale raster with different methods:
    # observe
    if(selected_method == "observe"){
      scaled_R <- normalize_r(R = R, MIN = cellStats(R, min), MAX = cellStats(R, max))}
    # reference
    if(selected_method == "reference"){
    scaled_R <- normalize_r(R = R, MIN = MIN, MAX = MAX)}
    # standarize
    if(selected_method == "standardize"){
      S <- scale(R)
      scaled_R <- normalize_r(R = S, MIN = cellStats(S, min), MAX = cellStats(S, max))}
  # return a scaled raster
  return(scaled_R)
}

subset_l <- function(the_list, the_items){
  the_list[the_items]
}

# solve "the smaller the better" cases
### solve_smaller_better_cases
solve_smaller_better_cases <- function(R, is_smaller_better){ 
  if(is_smaller_better){
    return(100 - R)
    } else {
      return(R)
    }
  }

# grind_r
grind_r <- function(filter_stack, operation){

    R = stackApply(x = filter_stack,
                   indices = rep(1, dim(filter_stack)[3]),
                   fun = sum)
    # if(dim(filter_stack)[3] > 0){  
      if (operation == "union") {the_filter = R / R}
      if (operation == "intersection") {the_filter = (R == dim(filter_stack)[3])}
      if (operation == "difference") {the_filter = (R == 1)}
    
    the_filter[the_filter != 1] <- NA
    
    return(the_filter)

  }

# get_spatial_results
get_spatial_results <- function(names_dataframe, 
                                selected_layers, 
                                path, 
                                filter_raster, 
                                fact
                                # mask_raster, 
                                # needs_resample
                                ){
  
  tabular = merge(x = names_dataframe, y = selected_layers)
  raster_file_names = tabular[,"preprocessed_raster"]
  if(length(raster_file_names) > 0){
    raster_file_paths  = paste0(path, raster_file_names)
    rasters = lapply(X = raster_file_paths, raster)
    if(fact != 1){
      # 0.92
      rasters = lapply(X = rasters, 
                       FUN = aggregate, 
                       fun = mean, 
                       fact = fact)        
      # rasters = lapply(X = rasters, 
      #                  FUN = resample, 
      #                  y = mask_raster)  
    }
    filtered = lapply(X = rasters, FUN = function(the_raster, the_filter){the_raster*the_filter}, filter_raster)
  scaled  = mapply(FUN = scale_r,
                   R = filtered,
                   selected_method = as.list(tabular$normalization_method),
                   MIN = as.list(tabular$lowest_value),
                   MAX = as.list(tabular$highest_value))
  normalized = mapply(FUN = solve_smaller_better_cases,
                     R = scaled,
                     is_smaller_better = as.list(tabular$smaller_better))
  if(length(raster_file_names) > 1){
    stacked  = stack(normalized)
    indexed = stackApply(x = stacked * tabular$weight,
                         indices = rep(1, length(tabular$weight)), 
                         fun = "sum", na.rm = FALSE) / sum(tabular$weight)
    
  } else{
    indexed = normalized[[1]]
  }
  } else {
  
    indexed <- raster(matrix(data = rep(NA, 10), nrow = 1, ncol = 10)) # raster1
    extent(indexed) <- c(-90, 90, -40, 40)
    projection(indexed) <- CRS("+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs")
    
  }

  return(indexed)
}

cheer_up <- c("#C44D58", 
              "#FF6B6B", 
              "#C7F464", 
              "#4ECDC4", 
              "#556270")

pal <- colorNumeric(palette = cheer_up, 
                    domain = -1:101, 
                    na.color = "transparent")

footer <- p("This tool was developed under the", a("World Bank Group's", href="http://www.worldbank.org", target="_blank"), " City Planning Labs intitiative, by ", 
            a("CAPSUS", href="http://www.capsus.mx", target="_blank"),
            "and", a("UP Technology", href="http://up.technology", target="_blank"), ", 2018.", align = "center")

waffle_plot <- function(i){
  
  options <- c("0 = index", "0 < index < 33", "34 < index < 66", "67 < index < 99", "100 = index")
  
  my_cut <- function(x){
    x = round(x, 0)
    answer = "ERROR"
    if(x == 0){answer = options[1]}
    if(x > 0 & x <= 33){answer = options[2]}
    if(x > 33 & x <= 66){answer = options[3]}
    if(x > 66 & x < 100){answer = options[4]}
    if(x == 100){answer = options[5]}
    return(answer)
  }
  
  the_label = c(sapply(X = as.list(i), FUN = my_cut), options)
  the_table = (table(the_label) - 1)[options]
  the_parts = round(100*the_table/length(i), 0)

  return(waffle(parts = the_parts, colors = cheer_up, title = "Graphical summary"))
}

something_went_wrong <- function(){
  sww <- raster(matrix(data = rep(NA, 10), nrow = 1, ncol = 10))
  extent(sww) <- c(-90, 90, -40, 40)
  projection(sww) <- CRS("+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs")
  return(sww)
}

# data_tab <- function(select_data, data_tab_selected_layer){
# 
#   data_tab_layer = read.csv(file = paste0("_data/",
#                                           select_data,
#                                           "/settings/layer_names.csv"),
#                             row.names = 1)
# 
#   the_row = data_tab_selected_layer
# 
#   # raster
#   the_raster_file = as.character(data_tab_layer[the_row, "preprocessed_raster"])
#   the_raster_path = paste0("_data/",
#                            select_data,
#                            "/layers/raster/",
#                            the_raster_file)
# 
#   the_raster = raster(the_raster_path)
# 
#   the_palette <- colorNumeric(cheer_up, values(the_raster),
#                        na.color = "transparent")
#   answer <- list()
#   answer$the_raster <- the_raster
#   answer$the_palette <- the_palette
# 
#   return(answer)
# }
