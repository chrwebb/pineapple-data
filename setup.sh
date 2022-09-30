#!/bin/bash

# Run initial setup of required schemas
psql postgres://$PGUSER:$PGPASSWORD@$PGHOST:$PGPORT/$PGDATABASE -v ON_ERROR_STOP=1 -f setup/sql/create_schemas_and_extensions.sql
psql postgres://$PGUSER:$PGPASSWORD@$PGHOST:$PGPORT/$PGDATABASE -v ON_ERROR_STOP=1 -f setup/sql/create_tables_and_views.sql

# wget, unzip and place in data folder
# ogr2ogr to postgres
mkdir utils

rm -f utils/db.ini
printf "[pg_connection]\nhost=$PGHOST\ndbname=$PGDATABASE\nuser=$PGUSER\nport=$PGPORT\npassword=$PGPASSWORD" > utils/db.ini

unzip -qun data/test/tz_canada.zip -d data/test/
ogr2ogr -f PostgreSQL PG:"host=$PGHOST user=$PGUSER dbname=$PGDATABASE" data/test/canada/tz_canada.shp -lco GEOMETRY_NAME=geom4326 -lco FID=gid -lco PRECISION=no -nlt PROMOTE_TO_MULTI -nln data.timezone -overwrite
rm -r data/test/canada

unzip -qun data/test/pf_grids.zip -d data/test/
gdalwarp -s_srs  "+proj=merc +lon_0=0 +lat_ts=0 +x_0=0 +y_0=0 +a=6378137 +b=6378137 +units=m +no_defs" -t_srs EPSG:4326 ./data/test/mp_aep_grid_10yr_all-season_mlc_bc_24h_ver1.tif ./data/test/mp_aep_grid_10yr_all-season_mlc_bc_24h_ver1_4326.tif
gdalwarp -s_srs  "+proj=merc +lon_0=0 +lat_ts=0 +x_0=0 +y_0=0 +a=6378137 +b=6378137 +units=m +no_defs" -t_srs EPSG:4326 ./data/test/mp_aep_grid_20yr_all-season_mlc_bc_24h_ver1.tif ./data/test/mp_aep_grid_20yr_all-season_mlc_bc_24h_ver1_4326.tif
gdalwarp -s_srs  "+proj=merc +lon_0=0 +lat_ts=0 +x_0=0 +y_0=0 +a=6378137 +b=6378137 +units=m +no_defs" -t_srs EPSG:4326 ./data/test/mp_aep_grid_50yr_all-season_mlc_bc_24h_ver1.tif ./data/test/mp_aep_grid_50yr_all-season_mlc_bc_24h_ver1_4326.tif
gdalwarp -s_srs  "+proj=merc +lon_0=0 +lat_ts=0 +x_0=0 +y_0=0 +a=6378137 +b=6378137 +units=m +no_defs" -t_srs EPSG:4326 ./data/test/mp_aep_grid_100yr_all-season_mlc_bc_24h_ver1.tif ./data/test/mp_aep_grid_100yr_all-season_mlc_bc_24h_ver1_4326.tif
gdalwarp -s_srs  "+proj=merc +lon_0=0 +lat_ts=0 +x_0=0 +y_0=0 +a=6378137 +b=6378137 +units=m +no_defs" -t_srs EPSG:4326 ./data/test/mp_aep_grid_10yr_all-season_mlc_bc_48h_ver1.tif ./data/test/mp_aep_grid_10yr_all-season_mlc_bc_48h_ver1_4326.tif
gdalwarp -s_srs  "+proj=merc +lon_0=0 +lat_ts=0 +x_0=0 +y_0=0 +a=6378137 +b=6378137 +units=m +no_defs" -t_srs EPSG:4326 ./data/test/mp_aep_grid_20yr_all-season_mlc_bc_48h_ver1.tif ./data/test/mp_aep_grid_20yr_all-season_mlc_bc_48h_ver1_4326.tif
gdalwarp -s_srs  "+proj=merc +lon_0=0 +lat_ts=0 +x_0=0 +y_0=0 +a=6378137 +b=6378137 +units=m +no_defs" -t_srs EPSG:4326 ./data/test/mp_aep_grid_50yr_all-season_mlc_bc_48h_ver1.tif ./data/test/mp_aep_grid_50yr_all-season_mlc_bc_48h_ver1_4326.tif
gdalwarp -s_srs  "+proj=merc +lon_0=0 +lat_ts=0 +x_0=0 +y_0=0 +a=6378137 +b=6378137 +units=m +no_defs" -t_srs EPSG:4326 ./data/test/mp_aep_grid_100yr_all-season_mlc_bc_48h_ver1.tif ./data/test/mp_aep_grid_100yr_all-season_mlc_bc_48h_ver1_4326.tif

raster2pgsql -d -C -s EPSG:4326 ./data/test/mp_aep_grid_10yr_all-season_mlc_bc_24h_ver1_4326.tif staging.pf_grids_10yr_24h | psql postgresql://$PGUSER:$PGPASSWORD@$PGHOST:$PGPORT/$PGDATABASE
raster2pgsql -d -C -s EPSG:4326 ./data/test/mp_aep_grid_20yr_all-season_mlc_bc_24h_ver1_4326.tif staging.pf_grids_20yr_24h | psql postgresql://$PGUSER:$PGPASSWORD@$PGHOST:$PGPORT/$PGDATABASE
raster2pgsql -d -C -s EPSG:4326 ./data/test/mp_aep_grid_50yr_all-season_mlc_bc_24h_ver1_4326.tif staging.pf_grids_50yr_24h | psql postgresql://$PGUSER:$PGPASSWORD@$PGHOST:$PGPORT/$PGDATABASE
raster2pgsql -d -C -s EPSG:4326 ./data/test/mp_aep_grid_100yr_all-season_mlc_bc_24h_ver1_4326.tif staging.pf_grids_100yr_24h | psql postgresql://$PGUSER:$PGPASSWORD@$PGHOST:$PGPORT/$PGDATABASE
raster2pgsql -d -C -s EPSG:4326 ./data/test/mp_aep_grid_10yr_all-season_mlc_bc_48h_ver1_4326.tif staging.pf_grids_10yr_48h | psql postgresql://$PGUSER:$PGPASSWORD@$PGHOST:$PGPORT/$PGDATABASE
raster2pgsql -d -C -s EPSG:4326 ./data/test/mp_aep_grid_20yr_all-season_mlc_bc_48h_ver1_4326.tif staging.pf_grids_20yr_48h | psql postgresql://$PGUSER:$PGPASSWORD@$PGHOST:$PGPORT/$PGDATABASE
raster2pgsql -d -C -s EPSG:4326 ./data/test/mp_aep_grid_50yr_all-season_mlc_bc_48h_ver1_4326.tif staging.pf_grids_50yr_48h | psql postgresql://$PGUSER:$PGPASSWORD@$PGHOST:$PGPORT/$PGDATABASE
raster2pgsql -d -C -s EPSG:4326 ./data/test/mp_aep_grid_100yr_all-season_mlc_bc_48h_ver1_4326.tif staging.pf_grids_100yr_48h | psql postgresql://$PGUSER:$PGPASSWORD@$PGHOST:$PGPORT/$PGDATABASE
rm data/test/mp_aep_grid_*

psql -h $PGHOST -d $PGDATABASE -U $PGUSER -p $PGPORT -v ON_ERROR_STOP=1 -f setup/sql/create_triggers_plus_trigger_functions.sql
psql -h $PGHOST -d $PGDATABASE -U $PGUSER -p $PGPORT -v ON_ERROR_STOP=1 -f setup/sql/create_app_functions.sql
psql -h $PGHOST -d $PGDATABASE -U $PGUSER -p $PGPORT -v ON_ERROR_STOP=1 -f setup/sql/populate_tables.sql
psql -h $PGHOST -d $PGDATABASE -U $PGUSER -p $PGPORT -v ON_ERROR_STOP=1 -f setup/sql/create_indexes.sql
psql -h $PGHOST -d $PGDATABASE -U $PGUSER -p $PGPORT -v ON_ERROR_STOP=1 -f setup/sql/create_tileserv_functions.sql

psql -h $PGHOST -d $PGDATABASE -U $PGUSER -p $PGPORT -v ON_ERROR_STOP=1 -v v1="$PGTILESERVER_PASSWORD" -f setup/sql/create_roles.sql
psql -h $PGHOST -d $PGDATABASE -U $PGUSER -p $PGPORT -v ON_ERROR_STOP=1 -f setup/sql/grant_permissions.sql
