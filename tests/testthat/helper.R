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

# Directory of the application. Tests run from tests/testthat.
root <- normalizePath(file.path(testthat::test_path(), "..", ".."))

# The lookup object reads its files relative to the application directory.
air_quality <- withr::with_dir(root, {
  source(file.path(root, "lib", "air.quality.madrid.R"))
  air.quality.madrid()
})

# Air quality data, one data frame per year.
files <- sort(list.files(file.path(root, "data"),
                         pattern = "^air\\.quality\\.madrid\\.[0-9]+\\.csv$",
                         full.names = TRUE))
names(files) <- sub("^.*\\.([0-9]+)\\.csv$", "\\1", files)
