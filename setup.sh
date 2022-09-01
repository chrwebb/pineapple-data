#!/bin/bash

# Run initial setup of required schemas
psql postgres://$PGUSER:$PGPASSWORD@$PGHOST:$PGPORT/$PGDATABASE -v ON_ERROR_STOP=1 -f setup/create_schemas_and_extensions.sql
psql postgres://$PGUSER:$PGPASSWORD@$PGHOST:$PGPORT/$PGDATABASE -v ON_ERROR_STOP=1 -f setup/create_roles.sql
psql postgres://$PGUSER:$PGPASSWORD@$PGHOST:$PGPORT/$PGDATABASE -v ON_ERROR_STOP=1 -f setup/create_tables_and_views.sql
psql postgres://$PGUSER:$PGPASSWORD@$PGHOST:$PGPORT/$PGDATABASE -v ON_ERROR_STOP=1 -f setup/grant_permissions.sql
psql postgres://$PGUSER:$PGPASSWORD@$PGHOST:$PGPORT/$PGDATABASE -v ON_ERROR_STOP=1 -f setup/create_functions_and_triggers.sql
psql postgres://$PGUSER:$PGPASSWORD@$PGHOST:$PGPORT/$PGDATABASE -v ON_ERROR_STOP=1 -f setup/populate_tables.sql
psql postgres://$PGUSER:$PGPASSWORD@$PGHOST:$PGPORT/$PGDATABASE -v ON_ERROR_STOP=1 -f setup/create_indexes.sql
psql postgres://$PGUSER:$PGPASSWORD@$PGHOST:$PGPORT/$PGDATABASE -v ON_ERROR_STOP=1 -f setup/seed_tables.sql


# wget, unzip and place in data folder
# ogr2ogr to postgres
mkdir utils

rm -f utils/db.ini
printf "[pg_connection]\nhost=$PGHOST\ndbname=$PGDATABASE\nuser=$PGUSER\nport=$PGPORT\npassword=$PGPASSWORD" > utils/db.ini

unzip -qun data/test/fires_4326.zip -d data/test/
ogr2ogr -f PostgreSQL PG:"host=$PGHOST user=$PGUSER dbname=$PGDATABASE" data/test/fires_4326.geojson -nln staging.fire_polygons
rm data/test/fires_4326.geojson

unzip -qun data/test/roads_4326.zip -d data/test/
ogr2ogr -f PostgreSQL PG:"host=$PGHOST user=$PGUSER dbname=$PGDATABASE" data/test/roads_4326.geojson -nln staging.road_lines
rm data/test/roads_4326.geojson