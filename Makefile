CC=R

.PHONY: deps run update test

all:

# Install the R packages needed to run the application, update the datasets
# and run the tests.
deps:
	${CC} -e "install.packages(c('dplyr', 'ggmap', 'ggplot2', 'gridExtra', 'jsonlite', 'remotes', 'scales', 'shiny', 'testthat', 'tidyr'), repos='https://cloud.r-project.org/');"
	${CC} -e "remotes::install_github('nramon/madrid.air');"

# Run the application at http://127.0.0.1:8080
run:
	${CC} -e "shiny::runApp(launch.browser = FALSE, port = 8080);"

# Download new air quality data. Use ARGS=--force to download everything again.
update:
	Rscript util/air.quality.update.R ${ARGS}

test:
	${CC} -e "testthat::test_dir('tests/testthat', stop_on_failure = TRUE);"
