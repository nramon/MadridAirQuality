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
library(tidyr)
library(dplyr)

# Object for parsing air quality data from: http://datos.madrid.es/portal/site/egob/menuitem.c05c1f754a33a9fbe4b2e4b284f1a5a0/?vgnextoid=aecb88a7e2b73410VgnVCM2000000c205a0aRCRD&vgnextchannel=374512b9ace9f310VgnVCM100000171f5a0aRCRD
air.quality.madrid <- function() {

	# Magnitudes from: http://datos.madrid.es/FWProjects/egob/contenidos/datasets/ficheros/MedioAmbiente_CalidadAire/INTPHORA-DIA_V2.2.pdf
	# Limits from http://ec.europa.eu/environment/air/quality/standards.htm
	magnitudes <- read.csv("data/magnitudes.csv", stringsAsFactors = FALSE)
	magnitudes <- magnitudes[order(magnitudes$Name),]

	# Stations from: http://datos.madrid.es/FWProjects/egob/contenidos/datasets/ficheros/MedioAmbiente_CalidadAire/INTPHORA-DIA_V2.2.pdf
	# Coordinates from: http://www.eea.europa.eu/data-and-maps/data/airbase-the-european-air-quality-database-8
	stations <- read.csv("data/stations.csv", stringsAsFactors = FALSE)
	stations <- stations[order(stations$Location),]

	list(
		# Return known magnitude abbreviations.
		magnitude.abbreviations = function () {
			magnitudes[, "Abbreviation"]
		},

		# Return known magnitudes.
		magnitude.limits = function (abbreviation = "") {
			magnitudes[magnitudes$Abbreviation == abbreviation, c("Limit", "LimitPeriod")]
		},

		# Return known magnitudes.
		magnitude.names = function () {
			magnitudes[, "Name"]
		},

		# Return magnitude units.
		magnitude.units = function () {
			magnitudes[, "Unit"]
		},

		# Return station codes.
		station.codes = function () {
			stations[, "Station"]
		},

		# Return station locations.
		station.locations = function () {
			stations[, "Location"]
		},

		# Return station locations.
		station.comments = function () {
			stations[, "Comments"]
		},

		# Return longitude and latitude values for each station.
		station.coordinates = function () {
			stations[, c("Station", "Longitude", "Latitude")]
		},

		# Save air quality data in a more readable CSV file.
		write.csv = function (url = '', output = '') {
			input <- basename(url)

			# Download the dataset. See: http://datos.madrid.es/portal/site/egob/menuitem.c05c1f754a33a9fbe4b2e4b284f1a5a0/?vgnextoid=aecb88a7e2b73410VgnVCM2000000c205a0aRCRD&vgnextchannel=374512b9ace9f310VgnVCM100000171f5a0aRCRD
			if (!file.exists(input)) {
				download.file(url, destfile = input, method = "wget")
			}
		
			# Parse it. See: http://datos.madrid.es/FWProjects/egob/contenidos/datasets/ficheros/MedioAmbiente_CalidadAire/INTPHORA-DIA_V2.2.pdf
			if (!grepl("-[0-7]-calidad", perl = T, input)) {
				air_quality <- read.fwf(input, widths=c(8, 2, 2, 2, 2, 2, rep(6, 31)), stringsAsFactors=F)
			}
			# There was an extra column before 2011 with the value 00.
			else {
				air_quality <- read.fwf(input, widths=c(8, 2, 2, 2, 2, 2, 2, rep(6, 31)), stringsAsFactors=F)

				# Remove the extra column.
				air_quality <- air_quality[,-7]
			}
	
			# Remove the measurement technique and period columns.
			air_quality <- air_quality[,-c(3, 4)]

			# Set appropriate column names.
			names(air_quality) <- c("Station", "Magnitude", "Year", "Month", c(1:31))
	
			# Leave one daily observation per row.
			air_quality <- gather(air_quality, Day, Value, 5:35)
			
			# Separate the validation code from the actual value.
			air_quality <- separate(air_quality, Value, c("Value", "ValidationCode"), sep=5)
			
			# Validation code V indicates valid data.
			air_quality <- filter(air_quality, ValidationCode == "V")
					
			# Remove the validation code from the dataset.
			air_quality <- air_quality[,-7]
			
			# Convert values to double precision numbers.
			air_quality$Value <- as.double(air_quality$Value)
	
			# Save magnitudes as a factor.
			air_quality$Magnitude <- factor(air_quality$Magnitude, levels=magnitudes[, "Magnitude"], labels=magnitudes[, "Abbreviation"])
			
			# Remove unknown magnitudes.
			# Note: There is no description for magnitude 85 in the docs!!!
			air_quality <- air_quality[!is.na(air_quality$Magnitude),]
			
			# Some station codes changed after 2011. Rename old codes to new codes.
			air_quality[air_quality$Station == 28079003, "Station"] <- 28079035 # Pza. del Carmen.
			air_quality[air_quality$Station == 28079005, "Station"] <- 28079039 # Barrio del Pilar.
			air_quality[air_quality$Station == 28079010, "Station"] <- 28079038 # Cuatro Caminos.
			air_quality[air_quality$Station == 28079013, "Station"] <- 28079040 # Vallecas.
			air_quality[air_quality$Station == 28079020, "Station"] <- 28079036 # Moratalaz.
			air_quality[air_quality$Station == 28079086, "Station"] <- 28079060 # Tres Olivos.

			# Fix the Day and Year columns.
			air_quality$Day <- as.integer(air_quality$Day)
			air_quality$Year <- air_quality$Year + 2000

			# Combine Day, Month and Year into Date.
			#air_quality <- unite(air_quality, "Date", Year, Month, Day, sep="-")

			# Rearrange the columns.
			air_quality <- air_quality[,c("Station", "Year", "Month", "Day", "Magnitude", "Value")]

			# Sort by date.
			air_quality <- arrange(air_quality, Month, Day)
		
			# Save the dataset to disk.
			write.csv(air_quality, file=output, row.names=F, quote=F)

			# Clean-up.
			unlink(input)
		}
	)
}

