#!/bin/bash

function main {
	# New data functions will need to be added to this list
	[ -z "$1" ] && { fire; road; } || $1
}

function fire {
	bcdata bc2pg fire-perimeters-historical --db_url postgres://$PGUSER:$PGPASSWORD@$PGHOST:$PGPORT/$PGDATABASE --table fire_historical --schema staging
	bcdata bc2pg fire-perimeters-current --db_url postgres://$PGUSER:$PGPASSWORD@$PGHOST:$PGPORT/$PGDATABASE --table fire_current --schema staging
	ogr2ogr -overwrite -a_srs EPSG:4326 -lco GEOMETRY_NAME=geom4326 -f PostgreSQL PG:"host=$PGHOST dbname=$PGDATABASE user=$PGUSER port=$PGPORT password=$PGPASSWORD" PG:"host=$PGHOST dbname=$PGDATABASE user=$PGUSER port=$PGPORT password=$PGPASSWORD" -sql "(SELECT fire_year, ST_Transform(geom,4326) as geom4326 FROM staging.fire_historical WHERE fire_year>DATE_PART('year', CURRENT_DATE)-5) UNION ALL (SELECT fire_year, ST_Transform(geom,4326) as geom4326 FROM staging.fire_current)" -nln data.fire_polygons
}

function road {
	bcdata bc2pg forest-tenure-road-section-lines --db_url postgres://$PGUSER:$PGPASSWORD@$PGHOST:$PGPORT/$PGDATABASE --table forest_roads --schema staging --promote_to_multi
	bcdata bc2pg digital-road-atlas-dra-master-partially-attributed-roads --db_url postgres://$PGUSER:$PGPASSWORD@$PGHOST:$PGPORT/$PGDATABASE --table road_atlas --schema staging --promote_to_multi
	ogr2ogr -overwrite -a_srs EPSG:4326 -lco GEOMETRY_NAME=geom4326 -f PostgreSQL PG:"host=$PGHOST dbname=$PGDATABASE user=$PGUSER port=$PGPORT password=$PGPASSWORD" PG:"host=$PGHOST dbname=$PGDATABASE user=$PGUSER port=$PGPORT password=$PGPASSWORD" -sql "(SELECT (ST_Dump(ST_Transform(geom,4326))).geom as geom4326 FROM staging.forest_roads) UNION ALL (SELECT (ST_Dump(ST_Transform(geom,4326))).geom as geom4326 FROM staging.road_atlas)" -nln data.road_lines
}

main "$@"