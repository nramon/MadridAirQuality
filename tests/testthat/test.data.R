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

# Air quality data for all the years. Read once, it is a large dataset.
years <- lapply(files, read.csv, stringsAsFactors = FALSE)

test_that("there is one dataset per year without gaps", {
  numbers <- as.integer(names(files))
  expect_true(length(numbers) > 0)
  expect_equal(numbers, seq(min(numbers), max(numbers)))
})

test_that("datasets have the expected format", {
  columns <- c("Station", "Year", "Month", "Day", "Magnitude", "Value")
  for (year in names(years)) {
    data <- years[[year]]
    expect_equal(names(data), columns, info = year)
    expect_true(nrow(data) > 0, info = year)

    # The year in the file name matches the data.
    expect_equal(unique(data$Year), as.integer(year), info = year)
    expect_true(all(data$Month %in% 1:12), info = year)
    expect_true(all(data$Day %in% 1:31), info = year)
    expect_true(is.numeric(data$Value), info = year)
    expect_false(anyNA(data$Value), info = year)
  }
})

test_that("stations and magnitudes are known", {
  for (year in names(years)) {
    data <- years[[year]]
    expect_equal(setdiff(data$Station, air_quality$station.codes()),
                 integer(0), info = year)
    expect_equal(setdiff(data$Magnitude, air_quality$magnitude.abbreviations()),
                 character(0), info = year)
  }
})

test_that("lookup tables are consistent", {
  magnitudes <- read.csv(file.path(root, "data", "magnitudes.csv"))
  expect_false(anyDuplicated(magnitudes$Magnitude) > 0)
  expect_false(anyDuplicated(magnitudes$Abbreviation) > 0)

  n <- length(air_quality$magnitude.abbreviations())
  expect_equal(length(air_quality$magnitude.names()), n)
  expect_equal(length(air_quality$magnitude.units()), n)

  n <- length(air_quality$station.codes())
  expect_false(anyDuplicated(air_quality$station.codes()) > 0)
  expect_equal(length(air_quality$station.locations()), n)
  expect_equal(length(air_quality$station.comments()), n)
  expect_equal(nrow(air_quality$station.coordinates()), n)
})

# NOx is approximately NO2 + 1.53 * NO. Swapping the labels of NO and NO2
# gives a median error of 7 or more in every year.
test_that("NO and NO2 are properly labeled", {
  for (year in names(years)) {
    data <- years[[year]]
    data <- data[data$Magnitude %in% c("NO", "NO2", "NOx"), ]
    data <- reshape(data[, c("Station", "Month", "Day", "Magnitude", "Value")],
                    idvar = c("Station", "Month", "Day"),
                    timevar = "Magnitude", direction = "wide")
    data <- data[complete.cases(data), ]
    expect_true(nrow(data) > 0, info = year)

    error <- median(abs(data$Value.NOx - (data$Value.NO2 + 1.53 * data$Value.NO)))
    expect_true(error < 2, info = year)
  }
})

test_that("limits are defined for NO2 but not for NO", {
  expect_equal(air_quality$magnitude.limits("NO2")$Limit, 200)
  expect_equal(air_quality$magnitude.limits("NO")$Limit, 0)
})
