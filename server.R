# Copyright (C) 2016 Ramon Novoa <ramonnovoa AT gmail DOT com>
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.	See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.	If not, see <http://www.gnu.org/licenses/>.
library(dplyr)
library(ggmap)
library(ggplot2)
library(gridExtra)
library(scales)
library(shiny)
library(tidyr)

# Instantiate an air.quality.madrid object.
source("lib/air.quality.madrid.R")
air_quality <- air.quality.madrid()

# Air quality data.
air_quality_data <- NA

# Filtered data from the air quality dataset.
year_data <- NA
month_data <- NA
day_data <- NA

# Current date. Used to reuse filtered data between tabs.
cur_year <- 0
cur_month <- 0
cur_day <- 0

# Current magnitude. Used to reuse filtered data between tabs.
cur_magnitude <- ""

# Map of madrid.
map <- NA

################################################################################
# Filter data for the current magnitude and date.
################################################################################
filterData <- function(magnitude=cur_magnitude, year=cur_year, month=cur_month, day=cur_day) {

	# Load a new dataset if the year changes.
	if (year != cur_year) {
		withProgress(message="Loading air quality data...", value=0, {
			air_quality_data <<- read.csv(paste("data/air.quality.madrid.", year, ".csv", sep=""))
		})
	}

	# Filter year data.
	if (magnitude != cur_magnitude ||
			year != cur_year) {
		year_data <<- filter(air_quality_data, Magnitude == magnitude)
	}

	# Filter month data.
	if (magnitude != cur_magnitude ||
			year != cur_year ||
			month != cur_month) {
		month_data <<- filter(year_data, Month == month)
	}

	# Filter day data.
	if (magnitude != cur_magnitude ||
			year != cur_year ||
			month != cur_month ||
			day != cur_day) {
		day_data <<- filter(month_data, Day == day)
	}

	cur_magnitude <<- magnitude
	cur_year <<- year
	cur_month <<- month
	cur_day <<- day
}

################################################################################
# Main server function.
################################################################################
shinyServer(function(input, output) {

	# Load the map.
	if (is.na(map)) {
		withProgress(message="Loading map data...", value=0, {
			map <<- readRDS("data/map.madrid.rds")
		})
	}
		
	# Plot a map.
	output$air_map <- renderPlot({
		
		# Filter data.
		filterData(input$magnitude, input$year, input$month, input$day)

		# Plot the map.
		day_data$Selected <- day_data$Station == input$station
		withProgress(message='Plotting...', value=0, {
			plot <- ggmap(map, darken = c(.5, "black")) +
			scale_colour_manual(name="", values=setNames(c('green', 'red'), c(T, F))) +
			geom_point(aes(x=Longitude, y=Latitude, size=Value, color=Selected), data=merge(day_data, air_quality$station.coordinates(), by="Station"), alpha=.6) +
			guides(colour=F) +
			guides(fill = guide_colorbar(barwidth = 0.5, barheight = 10)) +
			xlab(label='Longitude') +
			ylab(label='Latitude')
			plot
		})
	}, width=600, height=600)

	# Plot a chart.
	output$air_plot <- renderPlot({
		
		# Filter data.
		filterData(input$magnitude, input$year, input$month, input$day)

		# Get limits (if any) for the current magnitude.
		limits <- air_quality$magnitude.limits(input$magnitude)
		max_y <- max(year_data$Value, limits$Limit)

		# Plot the chart.
		withProgress(message='Plotting...', value=0, {

			# Year plot.
			year_data$Selected <- year_data$Station == input$station
			year_plot <- ggplot(aes(x=as.Date(Date), y=Value, color=Selected),
								data=unite(year_data, "Date", Year, Month, Day, sep="-")) +
			geom_point(show_guide = FALSE) +
			scale_colour_manual(name="", values=setNames(c('red', 'skyblue4'), c(T, F))) +
			scale_x_date(breaks="1 month", labels=date_format("%b")) +
			guides(colour=F) +
			expand_limits(y=max_y) +
			xlab(label=input$year) +
			ylab(label="")

			# Month plot.
			month_data$Selected <- month_data$Station == input$station
			month_plot <- ggplot(aes(x=as.Date(Date), y=Value, color=Selected),
								 data=unite(month_data, "Date", Year, Month, Day, sep="-")) +
			geom_jitter(width=0.4, height=0) +
			scale_colour_manual(name="", values=setNames(c('red', 'skyblue3'), c(T, F))) +
			guides(colour=F) +
			expand_limits(y=max_y) +
			scale_x_date(breaks="1 day", labels=date_format("%d")) +
			xlab(label=paste(month.name[input$month], " (horizontal jitter was added for clarity)")) +
			ylab(label="")

			# Day plot.
			day_data$Selected <- day_data$Station == input$station
			day_plot <- ggplot(aes(x=Location, y=Value, color=Selected, fill=Selected),
							 		data=merge(day_data, data.frame("Station" = air_quality$station.codes(), "Location" = air_quality$station.locations()), by="Station")) +
			geom_bar(stat="identity") +
			scale_fill_manual(name="", values=setNames(c('red', 'skyblue2'), c(T, F))) +
			scale_color_manual(name="", values=setNames(c('red', 'skyblue2'), c(T, F))) +
			guides(colour=F, fill=F) +
			expand_limits(y=max_y) +
			theme(axis.text.x=element_text(angle=45, hjust=1)) +
			xlab(label=input$day) +
			ylab(label="")

			# Draw limits.
			if (limits$Limit != 0) {
				year_plot <- year_plot +
							geom_hline(data = limits, aes(yintercept = Limit), colour = "red", show_guide = T) +
							ggtitle(paste("- Limit value:", limits$Limit, limits$LimitDescription)) +
							theme(plot.title = element_text(color="red"))
				month_plot <- month_plot + geom_hline(data = limits, aes(yintercept = Limit), colour = "red", show_guide = T)
				day_plot <- day_plot + geom_hline(data = limits, aes(yintercept = Limit), colour = "red", show_guide = T)
			}

			grid.arrange(year_plot, month_plot, day_plot, ncol=1)
		})
	}, width=600, height=600)

	# Generate a summary.
	output$summary <- renderPrint({
		
		# Filter data.
		filterData(input$magnitude, input$year, input$month, input$day)
		
		# Print a specific summary for the selected station.
		if (input$station != "All") {
				print(rbind("Year"=summary(year_data[year_data$Station == input$station, "Value"]),
							"Month"=summary(month_data[month_data$Station == input$station, "Value"]),
							"Day"=summary(day_data[day_data$Station == input$station, "Value"])))
		}
		# Print a summary for all the stations.
		else {
				print(rbind("Year"=summary(year_data$Value),
							"Month"=summary(month_data$Value),
							"Day"=summary(day_data$Value)))
		}
	}, width=600)
})
