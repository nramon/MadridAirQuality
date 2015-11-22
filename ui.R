library(shiny)
source("air.quality.madrid.R")

# Main UI function.
shinyUI(fixedPage(theme = "bootstrap.css",
  fixedRow(
	# Application title.
    column(12,
      div(style = "min-height: 100px; background: url(madrid_sky.png); background-repeat: no-repeat;",
        h1("Air Quality of Madrid", style="padding: 10px; color: #EEEEEE; text-shadow: 1px 1px #000000;")
      ),
      fixedRow(
		# User input.
        column(3,
          selectInput("magnitude", label = h3("Magnitude:"),                                                                                                        
                      choices = list("SO2 (µg/m)" = "SO2", "CO (mg/m)" = "CO", "NO (µg/m)" = "NO", "NO2 (µg/m)" = "NO2", "PM2.5 (µg/m)" = "PM2", "PM10 (µg/m)" = "PM1", "NOx (µg/m)" = "NOx", "O3 (µg/m)" = "O3", "TOL (µg/m)" = "TOL", "BEN (µg/m)" = "BEN", "EBE (µg/m)" = "EBE", "MXY (µg/m)" = "MXY", "PXY (µg/m)" = "PXY", "OXY (µg/m)" = "OXY", "TCH (mg/m)" = "TCH", "CH4 (mg/m)" = "CH4", "MHC (mg/m)" = "MHC", "UV (mW/m)" = "UV", "VV (m/s)" = "VV", "DV (Degrees or quadrant)" = "DV", "TMP (ºC)" = "TMP", "HR (%)" = "HR", "PRB (mb)" = "PRB", "RS (kW/m)" = "RS", "LL (l/m)" = "LL", "LLA (pH)" = "LLA")),
          sliderInput("year",
                      "Year:",
                      min = 2003,
                      max = 2015,
                      value = 2015),
          sliderInput("month",
                      "Month:",
                      min = 1,
                      max = 12,
                      value = 1),
          sliderInput("day",
                      "Day:",
                      min = 1,
                      max = 31,
                      value = 1)
        ),
		# Map and summary tabs
        column(9,
          tabsetPanel(
            tabPanel("Map", plotOutput("air_map")),
            tabPanel("Summary", verbatimTextOutput("summary"))
          )
        )
      )
    )
  ),
  fixedRow(
	# Application usage information.
    column(12,
      h3("Usage:"),
      p("This applications lets you display several magnitudes related to the air quality of the city of ", a("Madrid", href="https://en.wikipedia.org/wiki/Madrid"), " on a map. Simply select the magnitude, adjust the date and the map will be updated. The summary tab shows a numeric summary of the selected magnitude for the selected date. Due to their size, datasets are split and loaded by year.")
    )
  )
))
