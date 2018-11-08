# Libraries
# global.R

# FTP
ftp <- "your ftp address" # Please update with your own info
usr <- "your username"    # Please update with your own info
pas <- "your password"    # Please update with your own info
data_folder <- paste0("ftp://", usr, ":", pas, "@", ftp)

# Data
## shiny
library(shiny)
library(shinydashboard)
library(rhandsontable)

## raster
library(rgdal)
library(raster)
library(rasterVis)

# maps and plots
library(leaflet)
library(waffle)

# data and text
library(readr)
library(markdown)
library(reshape2)

# connections
library(RCurl)

# Functions
source("functions.R")

