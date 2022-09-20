#!/bin/bash

unzip -qun data/test/fires_4326.zip -d data/test/
ogr2ogr -overwrite -f PostgreSQL PG:"host=$PGHOST user=$PGUSER dbname=$PGDATABASE" data/test/fires_4326.geojson -dialect sqlite -nln staging.fire_polygons -sql "select fire_year, Geometry as geom4326, ST_Transform(Geometry, 3857) as geom3857 from fires_4326"
rm data/test/fires_4326.geojson

unzip -qun data/test/roads_4326.zip -d data/test/
ogr2ogr -overwrite -f PostgreSQL PG:"host=$PGHOST user=$PGUSER dbname=$PGDATABASE" data/test/roads_4326.geojson -dialect sqlite -nln staging.road_lines -sql "select Geometry as geom4326 from roads_4326"
rm data/test/roads_4326.geojson

unzip -qun data/test/fwa_4326.zip -d data/test/
ogr2ogr -overwrite -f PostgreSQL PG:"host=$PGHOST user=$PGUSER dbname=$PGDATABASE" data/test/fwa_4326.geojson -dialect sqlite -nln staging.freshwater_atlas_upstream -sql "select watershed_feature_id, Geometry as geom4326, ST_Transform(Geometry, 3857) as geom3857 from fwa_4326"
rm data/test/fwa_4326.geojson

psql -h $PGHOST -d $PGDATABASE -U $PGUSER -p $PGPORT -v ON_ERROR_STOP=1 -f setup/sql/seed_tables.sql
