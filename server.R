library(shiny)
library(dplyr)
library(ggmap)
library(ggplot2)
source("air.quality.madrid.R")

# Instantiate a new air.quality.madrid object.
#air.quality <- air.quality.madrid()

# Air quality data.
air_quality <- NA

# Filtered data from the air quality dataset.
filtered_data <- NA

# Current year. Due to their size, datasets are split by year.
cur_year <- NA

# Current date. Used to reuse filtered data between tabs.
cur_date <- NA

# Current magnitude. Used to reuse filtered data between tabs.
cur_magnitude <- NA

# Map of madrid.
map <- NA

# Load the dataset corresponding to the given year.
load_dataset <- function(year = cur_year) {
  if (is.na(cur_year) || year != cur_year) {
    withProgress(message = "Loading air quality data...", value = 0, {
      air_quality <<- read.csv(paste("data/air.quality.madrid.", year, ".csv", sep = ""))
      cur_year <<- year
    })
  }
}

# Filter data for the current magnitude and date.
filter_data <- function(magnitude = cur_magnitude, date = cur_date) {
  if (is.na(cur_magnitude) || magnitude != cur_magnitude || date != cur_date) {
    filtered_data <<- filter(air_quality, Magnitude == magnitude & Date == date)
    cur_magnitude <<- magnitude
    cur_date <<- date
  }
}

# Main server function.
shinyServer(function(input, output) {

  # Load the map.
  if (is.na(map)) {
    withProgress(message = "Loading map data...", value = 0, {
      map <<- get_map("Madrid", zoom = 11)
    })
  }
    
  # Plot a map.
  output$air_map <- renderPlot({
    
    # Load a new dataset if needed.
    load_dataset(input$year)
    
    # Filter data.
    filter_data(input$magnitude, paste(input$year, input$month, input$day, sep="-"))

    # Plot the map.
    withProgress(message = 'Plotting...', value = 0, {
      plot <- ggmap(map)
      plot <- plot + geom_point(aes(x = Longitude, y = Latitude, size = Value), data = filtered_data, alpha = .5)
      plot <- plot + xlab(label = 'Longitude')
      plot <- plot + ylab(label = 'Latitude')
      plot <- plot + scale_fill_discrete(name = "New Legend Title")
      plot
    })
  })

  # Generate a summary.
  output$summary <- renderPrint({
    
    # Load a new dataset if needed.
    load_dataset(input$year)
    
    # Filter data.
    filter_data(input$magnitude, paste(input$year, input$month, input$day, sep="-"))
    
    summary(filtered_data$Value)
  })
})
