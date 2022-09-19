#!/bin/bash

# Run initial setup of required schemas
psql postgres://$PGUSER:$PGPASSWORD@$PGHOST:$PGPORT/$PGDATABASE -v ON_ERROR_STOP=1 -f setup/sql/create_schemas_and_extensions.sql
psql postgres://$PGUSER:$PGPASSWORD@$PGHOST:$PGPORT/$PGDATABASE -v ON_ERROR_STOP=1 -f setup/sql/create_tables_and_views.sql
psql postgres://$PGUSER:$PGPASSWORD@$PGHOST:$PGPORT/$PGDATABASE -v ON_ERROR_STOP=1 -f setup/sql/grant_permissions.sql

# wget, unzip and place in data folder
# ogr2ogr to postgres
mkdir utils

rm -f utils/db.ini
printf "[pg_connection]\nhost=$PGHOST\ndbname=$PGDATABASE\nuser=$PGUSER\nport=$PGPORT\npassword=$PGPASSWORD" > utils/db.ini

unzip -qun data/test/tz_canada.zip -d data/test/
ogr2ogr -f PostgreSQL PG:"host=$PGHOST user=$PGUSER dbname=$PGDATABASE" data/test/canada/tz_canada.shp -lco GEOMETRY_NAME=geom4326 -lco FID=gid -lco PRECISION=no -nlt PROMOTE_TO_MULTI -nln data.timezone -overwrite
rm -r data/test/canada

psql postgres://$PGUSER:$PGPASSWORD@$PGHOST:$PGPORT/$PGDATABASE -v ON_ERROR_STOP=1 -f setup/sql/create_triggers_plus_trigger_functions.sql
psql postgres://$PGUSER:$PGPASSWORD@$PGHOST:$PGPORT/$PGDATABASE -v ON_ERROR_STOP=1 -f setup/sql/create_app_functions.sql
psql postgres://$PGUSER:$PGPASSWORD@$PGHOST:$PGPORT/$PGDATABASE -v ON_ERROR_STOP=1 -f setup/sql/populate_tables.sql
psql postgres://$PGUSER:$PGPASSWORD@$PGHOST:$PGPORT/$PGDATABASE -v ON_ERROR_STOP=1 -f setup/sql/create_indexes.sql
psql postgres://$PGUSER:$PGPASSWORD@$PGHOST:$PGPORT/$PGDATABASE -v ON_ERROR_STOP=1 -f setup/sql/create_tileserv_functions.sql

psql postgres://$PGUSER:$PGPASSWORD@$PGHOST:$PGPORT/$PGDATABASE -v ON_ERROR_STOP=1 pgtileserver_password=$PGTILESERVER_PASSWORD -f setup/sql/create_roles.sql