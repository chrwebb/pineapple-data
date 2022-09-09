#!/bin/bash

unzip -qun data/test/fires_4326.zip -d data/test/
ogr2ogr -overwrite -f PostgreSQL PG:"host=$PGHOST user=$PGUSER dbname=$PGDATABASE" data/test/fires_4326.geojson -dialect sqlite -nln staging.fire_polygons -sql "select fire_year, Geometry as geom4326 from fires_4326"
rm data/test/fires_4326.geojson

unzip -qun data/test/roads_4326.zip -d data/test/
ogr2ogr -overwrite -f PostgreSQL PG:"host=$PGHOST user=$PGUSER dbname=$PGDATABASE" data/test/roads_4326.geojson -dialect sqlite -nln staging.road_lines -sql "select Geometry as geom4326 from roads_4326"
rm data/test/roads_4326.geojson

psql postgres://$PGUSER:$PGPASSWORD@$PGHOST:$PGPORT/$PGDATABASE -v ON_ERROR_STOP=1 -f setup/seed_tables.sql