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
# Object for looking up the magnitudes and stations of the air quality data from:
# https://datos.madrid.es/dataset/201410-0-calidad-aire-diario
air.quality.madrid <- function() {

	# Magnitudes from the file format description published at the dataset above.
	# Limits from http://ec.europa.eu/environment/air/quality/standards.htm
	magnitudes <- read.csv("data/magnitudes.csv", stringsAsFactors = FALSE)
	magnitudes <- magnitudes[order(magnitudes$Name),]

	# Stations from the file format description published at the dataset above.
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
			magnitudes[magnitudes$Abbreviation == abbreviation, c("Limit", "LimitDescription")]
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
		}
	)
}

