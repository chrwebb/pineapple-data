#!/bin/bash

function main {
	# New data functions will need to be added to this list
	[ -z "$1" ] && { fire; road; freshwater_atlas; climate_normals; } || $1
}

function fire {
	bcdata bc2pg fire-perimeters-historical --db_url postgresql://$PGUSER:$PGPASSWORD@$PGHOST:$PGPORT/$PGDATABASE --table fire_historical --schema staging
	bcdata bc2pg fire-perimeters-current --db_url postgresql://$PGUSER:$PGPASSWORD@$PGHOST:$PGPORT/$PGDATABASE --table fire_current --schema staging
	psql postgresql://$PGUSER:$PGPASSWORD@$PGHOST:$PGPORT/$PGDATABASE -v ON_ERROR_STOP=1 -f setup/sql/populate_fire_table.sql
}

function road {
	bcdata bc2pg forest-tenure-road-section-lines --db_url postgresql://$PGUSER:$PGPASSWORD@$PGHOST:$PGPORT/$PGDATABASE --table forest_roads --schema staging --promote_to_multi
	bcdata bc2pg digital-road-atlas-dra-master-partially-attributed-roads --db_url postgresql://$PGUSER:$PGPASSWORD@$PGHOST:$PGPORT/$PGDATABASE --table road_atlas --schema staging --promote_to_multi
	psql postgresql://$PGUSER:$PGPASSWORD@$PGHOST:$PGPORT/$PGDATABASE -v ON_ERROR_STOP=1 -f setup/sql/populate_road_table.sql
}

function freshwater_atlas {
	bcdata bc2pg freshwater-atlas-watersheds --db_url postgresql://$PGUSER:$PGPASSWORD@$PGHOST:$PGPORT/$PGDATABASE --table freshwater_atlas --schema data
}

function climate_normals {
	wget -P ./data/ climatena.ca/rasterFiles/WNA/800m/Normal_1991_2020MSY/PPT01.tif
	wget -P ./data/ climatena.ca/rasterFiles/WNA/800m/Normal_1991_2020MSY/PPT02.tif
	wget -P ./data/ climatena.ca/rasterFiles/WNA/800m/Normal_1991_2020MSY/PPT03.tif
	wget -P ./data/ climatena.ca/rasterFiles/WNA/800m/Normal_1991_2020MSY/PPT04.tif
	wget -P ./data/ climatena.ca/rasterFiles/WNA/800m/Normal_1991_2020MSY/PPT05.tif
	wget -P ./data/ climatena.ca/rasterFiles/WNA/800m/Normal_1991_2020MSY/PPT06.tif
	wget -P ./data/ climatena.ca/rasterFiles/WNA/800m/Normal_1991_2020MSY/PPT07.tif
	wget -P ./data/ climatena.ca/rasterFiles/WNA/800m/Normal_1991_2020MSY/PPT08.tif
	wget -P ./data/ climatena.ca/rasterFiles/WNA/800m/Normal_1991_2020MSY/PPT09.tif
	wget -P ./data/ climatena.ca/rasterFiles/WNA/800m/Normal_1991_2020MSY/PPT10.tif
	wget -P ./data/ climatena.ca/rasterFiles/WNA/800m/Normal_1991_2020MSY/PPT11.tif
	wget -P ./data/ climatena.ca/rasterFiles/WNA/800m/Normal_1991_2020MSY/PPT12.tif

	gdalbuildvrt ./data/test.vrt ./data/PPT01.tif

	python setup/python/watershed_centroid_precip.py
}

main "$@"