library(tidyr)
library(dplyr)

# Object for parsing air quality data from: http://datos.madrid.es/portal/site/egob/menuitem.c05c1f754a33a9fbe4b2e4b284f1a5a0/?vgnextoid=aecb88a7e2b73410VgnVCM2000000c205a0aRCRD&vgnextchannel=374512b9ace9f310VgnVCM100000171f5a0aRCRD
air.quality.madrid <- function() {

	# Magnitudes from: http://datos.madrid.es/FWProjects/egob/contenidos/datasets/ficheros/MedioAmbiente_CalidadAire/INTPHORA-DIA_V2.2.pdf
	magnitudes <- c("SO2", "CO", "NO", "NO2", "PM2.5", "PM10", "NOx", "O3", "TOL", "BEN", "EBE", "MXY", "PXY", "OXY", "TCH", "CH4", "NMHC", "UV", "VV", "DV", "TMP", "HR", "PRB", "RS", "LL", "LLA")

	# Station codes from: http://datos.madrid.es/FWProjects/egob/contenidos/datasets/ficheros/MedioAmbiente_CalidadAire/INTPHORA-DIA_V2.2.pdf
	madrid_stations <- c('28079001', '28079002', '28079003', '28079035', '28079004', '28079005', '28079039', '28079006', '28079007', '28079008', '28079009', '28079010', '28079038', '28079011', '28079012', '28079013', '28079040', '28079014', '28079015', '28079016', '28079017', '28079018', '28079019', '28079020', '28079036', '28079021', '28079022', '28079023', '28079024', '28079025', '28079026', '28079027', '28079047', '28079048', '28079049', '28079050', '28079054', '28079055', '28079056', '28079057', '28079058', '28079059', '28079086', '28079060', '28079099')

	# Download station information. See: http://www.eea.europa.eu/data-and-maps/data/airbase-the-european-air-quality-database-8
	if (!file.exists("AirBase_v8_stations.zip")) {
		download.file("http://ftp.eea.europa.eu/www/AirBase_v8/AirBase_v8_stations.zip", destfile="AirBase_v8_stations.zip", method="wget")
		unzip("AirBase_v8_stations.zip")
	}

	# Save station latitude and longitude.
	stations <- read.csv("AirBase_v8_stations.csv", sep="\t")
	stations <- select(stations, station_local_code, station_longitude_deg, station_latitude_deg)
	stations$station_local_code <- as.character(stations$station_local_code)

	list(
		# Return known magnitudes.
		magnitudes = function () {
			magnitudes
		},

		# Return known stations in Madrid.
		stations = function () {
			madrid_stations
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
	
			# Set appropriate column names.
			names(air_quality) <- c("Station", "Magnitude", "AnalysisTechnique", "AnalysisPeriod", "Year", "Month", c(1:31))
	
			# Leave one daily observation per row.
			air_quality <- gather(air_quality, Day, Value, 7:37)
			
			# Separate the validation code from the actual value.
			air_quality <- separate(air_quality, Value, c("Value", "ValidationCode"), sep=5)
			
			# Validation code V indicates valid data.
			air_quality <- filter(air_quality, ValidationCode == "V")
					
			# Remove the validation code from the dataset.
			air_quality <- air_quality[,-9]
			
			# Convert values to double precision numbers.
			air_quality$Value <- as.double(air_quality$Value)
	
			# Save magnitudes as a factor.
			air_quality$Magnitude <- factor(air_quality$Magnitude, levels=c(01, 06, 07, 08, 09, 10, 12, 14, 20, 30, 35, 37, 38, 39, 42, 43, 44, 80, 81, 82, 83, 86, 87, 88, 89, 92), labels=magnitudes)
			
			# Remove unknown magnitudes.
			# Note: There is no description for magnitude 85 in the docs!!!
			air_quality <- air_quality[!is.na(air_quality$Magnitude),]
			
			# Save station codes as strings
			air_quality$Station <- as.character(air_quality$Station)

			# Some station codes changed after 2011. Rename old codes to new codes.
			air_quality[air_quality$Station == "28079003", "Station"] <- "28079035" # Pza. del Carmen.
			air_quality[air_quality$Station == "28079005", "Station"] <- "28079039" # Barrio del Pilar.
			air_quality[air_quality$Station == "28079010", "Station"] <- "28079038" # Cuatro Caminos.
			air_quality[air_quality$Station == "28079013", "Station"] <- "28079040" # Vallecas.
			air_quality[air_quality$Station == "28079020", "Station"] <- "28079036" # Moratalaz.
			air_quality[air_quality$Station == "28079086", "Station"] <- "28079060" # Tres Olivos.

			# Combine Day, Month and Year into Date.
			air_quality$Day <- as.numeric(air_quality$Day)
			air_quality$Year <- air_quality$Year + 2000
			air_quality <- unite(air_quality, "Date", Year, Month, Day, sep="-")
		
			# Add station latitude and longitude coordinates to the air quality dataset.
			air_quality <- merge(air_quality, stations, by.x="Station", by.y="station_local_code")
			names(air_quality)[7] <- "Longitude"
			names(air_quality)[8] <- "Latitude"

			# Save the dataset to disk.
			write.csv(air_quality, file=output, row.names=F)
		}
	)
}

#air.quality <- air.quality.madrid()
#air.quality$write.csv("http://datos.madrid.es/egob/catalogo/201410-12-calidad-aire-diario.txt", "air.quality.madrid.2015.csv")
#air.quality$write.csv("http://datos.madrid.es/egob/catalogo/201410-11-calidad-aire-diario.txt", "air.quality.madrid.2014.csv")
#air.quality$write.csv("http://datos.madrid.es/egob/catalogo/201410-10-calidad-aire-diario.txt", "air.quality.madrid.2013.csv")
#air.quality$write.csv("http://datos.madrid.es/egob/catalogo/201410-9-calidad-aire-diario.txt", "air.quality.madrid.2012.csv")
#air.quality$write.csv("http://datos.madrid.es/egob/catalogo/201410-8-calidad-aire-diario.txt", "air.quality.madrid.2011.csv")
#air.quality$write.csv("http://datos.madrid.es/egob/catalogo/201410-7-calidad-aire-diario.txt", "air.quality.madrid.2010.csv")
#air.quality$write.csv("http://datos.madrid.es/egob/catalogo/201410-6-calidad-aire-diario.txt", "air.quality.madrid.2009.csv")
#air.quality$write.csv("http://datos.madrid.es/egob/catalogo/201410-5-calidad-aire-diario.txt", "air.quality.madrid.2008.csv")
#air.quality$write.csv("http://datos.madrid.es/egob/catalogo/201410-4-calidad-aire-diario.txt", "air.quality.madrid.2007.csv")
#air.quality$write.csv("http://datos.madrid.es/egob/catalogo/201410-3-calidad-aire-diario.txt", "air.quality.madrid.2006.csv")
#air.quality$write.csv("http://datos.madrid.es/egob/catalogo/201410-2-calidad-aire-diario.txt", "air.quality.madrid.2005.csv")
#air.quality$write.csv("http://datos.madrid.es/egob/catalogo/201410-1-calidad-aire-diario.txt", "air.quality.madrid.2004.csv")
#air.quality$write.csv("http://datos.madrid.es/egob/catalogo/201410-0-calidad-aire-diario.txt", "air.quality.madrid.2003.csv")
