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
# Downloads the map of Madrid used by the application. The map tiles are
# provided by Stadia Maps, which requires an API key (see
# https://client.stadiamaps.com/). Set it in the STADIA_MAPS_API_KEY
# environment variable:
#
#   STADIA_MAPS_API_KEY=<key> Rscript util/madrid.map.update.R

library(ggmap)

register_stadiamaps(Sys.getenv("STADIA_MAPS_API_KEY"), write = FALSE)
map <- get_stadiamap(bbox = c(left = -3.774444, bottom = 40.346944, right = -3.575, top = 40.518056),
                     zoom = 12, maptype = "stamen_toner_lite")
saveRDS(map, file = "data/map.madrid.rds")
