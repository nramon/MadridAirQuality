# MadridAirQuality
This is a web application written in R as a project for the [Developing Data Products](http://www.coursera.org/learn/data-products) course. It displays several magnitudes related to the air quality of the city of [Madrid](http://en.wikipedia.org/wiki/Madrid). The original raw data can be downloaded from [http://datos.madrid.es](http://datos.madrid.es/portal/site/egob/menuitem.c05c1f754a33a9fbe4b2e4b284f1a5a0/?vgnextoid=aecb88a7e2b73410VgnVCM2000000c205a0aRCRD&vgnextchannel=374512b9ace9f310VgnVCM100000171f5a0aRCRD).

## Running the MadridAirQuality web application
To run the application locally you have to install [R](http://www.r-project.org/).

Clone the repository and start the R CMD interface:

```
git clone https://github.com/nramon/MadridAirQuality.git
cd MadridAirQuality
R
```

From the R CMD interface install the required R packages:

```
install.packages("dplyr")
install.packages("ggmap")
install.packages("ggplot2")
install.packages("gridExtra")
install.packages("shiny")
install.packages("tidyr")
```

Load the shiny package and run the web application:

```
library(shiny)
runApp(launch.browser = FALSE, port = 8080)
```

Lastly, point your browser to: http://127.0.0.1:8080

## Updating the air quality datasets

To update the air quality datasets (and download any new datasets) run the following command from the MadridAirQuality directory:

```
Rscript util/air.quality.update.R
```

## Updating the map

The map of the city of Madrid is cached, it is not downloaded every time the application is run. If for any reason you want to update it run the following command from the MadridAirQuality directory:

```
Rscript util/madrid.map.update.R
```

## Screenshot
![screenshot](https://raw.githubusercontent.com/nramon/MadridAirQuality/master/screenshot.png)

## Online demo
There is an online demo at http://nramon.shinyapps.io/MadridAirQuality/, but the bandwidth is limited and it may be down for long periods of time.
