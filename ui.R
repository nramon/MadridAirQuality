# Copyright (C) 2016 Ramon Novoa <ramonnovoa AT gmail DOT com>
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
library(shiny)

# Instantiate an air.quality.madrid object.
source("air.quality.madrid.R")
air_quality <- air.quality.madrid()

# List years with available data.
years <- as.integer(sub("^.*\\.(\\d+)\\.csv$", "\\1", dir("data", pattern = "air.quality.madrid.*.csv"), perl = TRUE))

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
          selectInput("magnitude", label = h3("Magnitude"),
		              choices = setNames(air_quality$magnitude.abbreviations(),
					                             paste(air_quality$magnitude.names(),
												       " (",
													   air_quality$magnitude.units(),
													   ")",
													   sep = ""))
					  ),
          selectInput("station", label = h4("Station"),
		              choices = setNames(c("All", air_quality$station.codes()), c("",
					  
					                              paste(air_quality$station.locations(),
												       ifelse(air_quality$station.comments() == "", "", " - "),
													   air_quality$station.comments(),
													   sep = "")))
					  ),
          sliderInput("year",
                      "Year:",
                      min = min(years),
                      max = max(years),
                      value = max(years),
					  step = 1),
          sliderInput("month",
                      "Month:",
                      min = 1,
                      max = 12,
                      value = 1,
					  step = 1),
          sliderInput("day",
                      "Day:",
                      min = 1,
                      max = 31,
                      value = 1,
					  step = 1)
        ),
		# Map and summary tabs.
        column(9,
          tabsetPanel(
            tabPanel("Plot", plotOutput("air_plot")),
            tabPanel("Map", plotOutput("air_map")),
            tabPanel("Summary", verbatimTextOutput("summary"))
          )
        )
      )
    )
  ),
  fixedRow(
	# Application information.
    column(12,
      h3("About"),
      p("Source code available at: ", a("GitHub", href="https://github.com/nramon/MadridAirQuality")),
      p("Air quality data from: ", a("Ayuntamiento de Madrid", href="http://datos.madrid.es/portal/site/egob/menuitem.c05c1f754a33a9fbe4b2e4b284f1a5a0/?vgnextoid=aecb88a7e2b73410VgnVCM2000000c205a0aRCRD&vgnextchannel=374512b9ace9f310VgnVCM100000171f5a0aRCRD")),
      p("Air quality limit values from: ", a("European Commission", href="http://ec.europa.eu/environment/air/quality/standards.htm")),
      p("Station geolocation data from: ", a("European Environment Agency", href="http://www.eea.europa.eu/data-and-maps/data/airbase-the-european-air-quality-database-8")),
	  p("Maps from: ", a("Google Maps", href="http://maps.google.com"))
    )
  )
))
