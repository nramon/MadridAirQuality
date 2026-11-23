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

# Updates the air quality datasets in data/ with the daily data published at:
# https://datos.madrid.es/dataset/201410-0-calidad-aire-diario
#
# Usage: Rscript util/air.quality.update.R [--force]
#
# One CSV file is published per year (the most recent years are published
# together in a single file). Years that have already been downloaded are
# skipped unless --force is given. The files for the most recent years are
# always downloaded because they are updated regularly.

library(jsonlite)
library(madrid.air)

force <- "--force" %in% commandArgs(trailingOnly = TRUE)

# List the files published in the dataset. The description of each file ends
# with the year, or with "Desde <year>" for the file with the latest years.
api <- "https://datos.madrid.es/api/3/action/package_show?id=201410-0-calidad-aire-diario"
resources <- fromJSON(api)$result$resources
resources <- resources[resources$format == "CSV", ]
resources$latest <- grepl("^.*Desde [0-9]{4}$", resources$description)
resources$year <- as.integer(sub("^.*?([0-9]{4})$", "\\1", resources$description))

for (idx in order(resources$year)) {
	year <- resources$year[idx]
	output <- paste("data/air.quality.madrid.", year, ".csv", sep = "")

	# Years that were already downloaded do not change.
	if (!force && !resources$latest[idx] && file.exists(output)) {
		next
	}

	# Download and parse the dataset.
	message("Downloading ", resources$description[idx], "...")
	input <- tempfile(fileext = ".csv")
	download.file(resources$url[idx], destfile = input, mode = "wb", quiet = TRUE)
	air_quality <- madrid.air.parse(input)
	unlink(input)

	# Save one file per year.
	for (y in sort(unique(air_quality$Year))) {
		output <- paste("data/air.quality.madrid.", y, ".csv", sep = "")
		write.csv(air_quality[air_quality$Year == y, ], file = output, row.names = FALSE, quote = FALSE)
	}
}
