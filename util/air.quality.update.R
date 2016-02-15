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
source("lib/air.quality.madrid.R")

# Update CSV files with data from: http://datos.madrid.es/portal/site/egob/menuitem.c05c1f754a33a9fbe4b2e4b284f1a5a0/?vgnextoid=aecb88a7e2b73410VgnVCM2000000c205a0aRCRD&vgnextchannel=374512b9ace9f310VgnVCM100000171f5a0aRCRD
tryCatch({
	air.quality <- air.quality.madrid()
	for (idx in seq(0, 99)) {
		input <- paste("http://datos.madrid.es/egob/catalogo/201410-", idx, "-calidad-aire-diario.txt", sep = "")

		# The first dataset (201410-0-calidad-aire-diario.txt) corresponds to 2003.
		output <- paste("data/air.quality.madrid.", 2003 + idx, ".csv", sep = "")

		air.quality$write.csv(input, output)
	}
}, finally = {
})

