#!/bin/bash

# Run initial setup of required schemas
psql postgres://$PGUSER:$PGPASSWORD@$PGHOST:$PGPORT/$PGDATABASE -v ON_ERROR_STOP=1 -f setup/create_schemas_and_extensions.sql
psql postgres://$PGUSER:$PGPASSWORD@$PGHOST:$PGPORT/$PGDATABASE -v ON_ERROR_STOP=1 -f setup/create_roles.sql
psql postgres://$PGUSER:$PGPASSWORD@$PGHOST:$PGPORT/$PGDATABASE -v ON_ERROR_STOP=1 -f setup/create_tables_and_views.sql
psql postgres://$PGUSER:$PGPASSWORD@$PGHOST:$PGPORT/$PGDATABASE -v ON_ERROR_STOP=1 -f setup/grant_permissions.sql

# wget, unzip and place in data folder
# ogr2ogr to postgres
mkdir utils

rm -f utils/db.ini
printf "[pg_connection]\nhost=$PGHOST\ndbname=$PGDATABASE\nuser=$PGUSER\nport=$PGPORT\npassword=$PGPASSWORD" > utils/db.ini

wget https://pub.data.gov.bc.ca/datasets/cdfc2d7b-c046-4bf0-90ac-4897232619e1/prot_current_fire_polys.zip
wget https://www.for.gov.bc.ca/ftp/HPR/external/\!publish/Maps_and_Data/GoogleEarth/WMB_Fires/BC%20Fire%20Perimeters%202017-2019.kmz
wget https://www.for.gov.bc.ca/ftp/HPR/external/\!publish/Maps_and_Data/GoogleEarth/WMB_Fires/BC_Fire_Points_and_Perimeters_2019_2021.kmz

unzip -qun prot_current_fire_polys.zip -d data/test/
rm prot_current_fire_polys.zip
ogr2ogr -f PostgreSQL PG:"host=$PGHOST user=$PGUSER dbname=$PGDATABASE" data/test/prot_current_fire_polys.shp -dialect sqlite -nln data.fire_polygons -sql "select fire_year, (ST_Dump(Geometry)).geom as geom4326 from prot_current_fire_polys"
rm data/test/prot_current_fire_polys.*

unzip -qun 'BC Fire Perimeters 2017-2019.kmz' -d data/test/
rm 'BC Fire Perimeters 2017-2019.kmz'
ogr2ogr -f GeoJSON data/test/fire_2017.geojson data/test/doc.kml 'BC Fire Perimeter 2017'
ogr2ogr -f GeoJSON data/test/fire_2018.geojson data/test/doc.kml 'BC Fire Perimeter 2018'
ogr2ogr -f GeoJSON data/test/fire_2019.geojson data/test/doc.kml 'BC Fire Perimeter 2019'
rm data/test/doc.kml

unzip -qun BC_Fire_Points_and_Perimeters_2019_2021.kmz -d data/test/
rm BC_Fire_Points_and_Perimeters_2019_2021.kmz
ogr2ogr -f GeoJSON data/test/fire_2020.geojson data/test/doc.kml 'BC Fire Perimeter 2020'
ogr2ogr -f GeoJSON data/test/fire_2021.geojson data/test/doc.kml 'BC Fire Perimeter 2021'
rm data/test/doc.kml

ogr2ogr -f PostgreSQL PG:"host=$PGHOST user=$PGUSER dbname=$PGDATABASE" data/test/fire_2017.geojson -append -dialect sqlite -nln data.fire_polygons -sql "select 2017 as fire_year, Geometry as geom4326 from 'BC Fire Perimeter 2017'"
ogr2ogr -f PostgreSQL PG:"host=$PGHOST user=$PGUSER dbname=$PGDATABASE" data/test/fire_2018.geojson -append -dialect sqlite -nln data.fire_polygons -sql "select 2018 as fire_year, Geometry as geom4326 from 'BC Fire Perimeter 2018'"
ogr2ogr -f PostgreSQL PG:"host=$PGHOST user=$PGUSER dbname=$PGDATABASE" data/test/fire_2019.geojson -append -dialect sqlite -nln data.fire_polygons -sql "select 2019 as fire_year, Geometry as geom4326 from 'BC Fire Perimeter 2019'"
ogr2ogr -f PostgreSQL PG:"host=$PGHOST user=$PGUSER dbname=$PGDATABASE" data/test/fire_2020.geojson -append -dialect sqlite -nln data.fire_polygons -sql "select 2020 as fire_year, Geometry as geom4326 from 'BC Fire Perimeter 2020'"
ogr2ogr -f PostgreSQL PG:"host=$PGHOST user=$PGUSER dbname=$PGDATABASE" data/test/fire_2021.geojson -append -dialect sqlite -nln data.fire_polygons -sql "select 2021 as fire_year, Geometry as geom4326 from 'BC Fire Perimeter 2021'"

rm data/test/fire_*

# unzip -qun data/test/roads_4326.zip -d data/test/
# ogr2ogr -f PostgreSQL PG:"host=$PGHOST user=$PGUSER dbname=$PGDATABASE" data/test/roads_4326.geojson -dialect sqlite -nln data.road_lines -sql "select Geometry as geom4326 from roads_4326"
# rm data/test/roads_4326.geojson

psql postgres://$PGUSER:$PGPASSWORD@$PGHOST:$PGPORT/$PGDATABASE -v ON_ERROR_STOP=1 -f setup/create_functions_and_triggers.sql
psql postgres://$PGUSER:$PGPASSWORD@$PGHOST:$PGPORT/$PGDATABASE -v ON_ERROR_STOP=1 -f setup/populate_tables.sql
psql postgres://$PGUSER:$PGPASSWORD@$PGHOST:$PGPORT/$PGDATABASE -v ON_ERROR_STOP=1 -f setup/create_indexes.sql
psql postgres://$PGUSER:$PGPASSWORD@$PGHOST:$PGPORT/$PGDATABASE -v ON_ERROR_STOP=1 -f setup/seed_tables.sql
