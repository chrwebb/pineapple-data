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

gdal_translate -projwin_srs EPSG:4326 -projwin -121.55689 50.52891 -120.36968 49.07425 ./data/PPT01.tif ./data/PPT01_clip.tif
gdal_translate -projwin_srs EPSG:4326 -projwin -121.55689 50.52891 -120.36968 49.07425 ./data/PPT02.tif ./data/PPT02_clip.tif
gdal_translate -projwin_srs EPSG:4326 -projwin -121.55689 50.52891 -120.36968 49.07425 ./data/PPT03.tif ./data/PPT03_clip.tif
gdal_translate -projwin_srs EPSG:4326 -projwin -121.55689 50.52891 -120.36968 49.07425 ./data/PPT04.tif ./data/PPT04_clip.tif
gdal_translate -projwin_srs EPSG:4326 -projwin -121.55689 50.52891 -120.36968 49.07425 ./data/PPT05.tif ./data/PPT05_clip.tif
gdal_translate -projwin_srs EPSG:4326 -projwin -121.55689 50.52891 -120.36968 49.07425 ./data/PPT06.tif ./data/PPT06_clip.tif
gdal_translate -projwin_srs EPSG:4326 -projwin -121.55689 50.52891 -120.36968 49.07425 ./data/PPT07.tif ./data/PPT07_clip.tif
gdal_translate -projwin_srs EPSG:4326 -projwin -121.55689 50.52891 -120.36968 49.07425 ./data/PPT08.tif ./data/PPT08_clip.tif
gdal_translate -projwin_srs EPSG:4326 -projwin -121.55689 50.52891 -120.36968 49.07425 ./data/PPT09.tif ./data/PPT09_clip.tif
gdal_translate -projwin_srs EPSG:4326 -projwin -121.55689 50.52891 -120.36968 49.07425 ./data/PPT10.tif ./data/PPT10_clip.tif
gdal_translate -projwin_srs EPSG:4326 -projwin -121.55689 50.52891 -120.36968 49.07425 ./data/PPT11.tif ./data/PPT11_clip.tif
gdal_translate -projwin_srs EPSG:4326 -projwin -121.55689 50.52891 -120.36968 49.07425 ./data/PPT11.tif ./data/PPT12_clip.tif

raster2pgsql -d -C -s 4326 -t 100x100 ./data/PPT01_clip.tif data.climate_normals_ppt1 | psql postgresql://$PGUSER:$PGPASSWORD@$PGHOST:$PGPORT/$PGDATABASE
raster2pgsql -d -C -s 4326 -t 100x100 ./data/PPT02_clip.tif data.climate_normals_ppt2 | psql postgresql://$PGUSER:$PGPASSWORD@$PGHOST:$PGPORT/$PGDATABASE
raster2pgsql -d -C -s 4326 -t 100x100 ./data/PPT03_clip.tif data.climate_normals_ppt3 | psql postgresql://$PGUSER:$PGPASSWORD@$PGHOST:$PGPORT/$PGDATABASE
raster2pgsql -d -C -s 4326 -t 100x100 ./data/PPT04_clip.tif data.climate_normals_ppt4 | psql postgresql://$PGUSER:$PGPASSWORD@$PGHOST:$PGPORT/$PGDATABASE
raster2pgsql -d -C -s 4326 -t 100x100 ./data/PPT05_clip.tif data.climate_normals_ppt5 | psql postgresql://$PGUSER:$PGPASSWORD@$PGHOST:$PGPORT/$PGDATABASE
raster2pgsql -d -C -s 4326 -t 100x100 ./data/PPT06_clip.tif data.climate_normals_ppt6 | psql postgresql://$PGUSER:$PGPASSWORD@$PGHOST:$PGPORT/$PGDATABASE
raster2pgsql -d -C -s 4326 -t 100x100 ./data/PPT07_clip.tif data.climate_normals_ppt7 | psql postgresql://$PGUSER:$PGPASSWORD@$PGHOST:$PGPORT/$PGDATABASE
raster2pgsql -d -C -s 4326 -t 100x100 ./data/PPT08_clip.tif data.climate_normals_ppt8 | psql postgresql://$PGUSER:$PGPASSWORD@$PGHOST:$PGPORT/$PGDATABASE
raster2pgsql -d -C -s 4326 -t 100x100 ./data/PPT09_clip.tif data.climate_normals_ppt9 | psql postgresql://$PGUSER:$PGPASSWORD@$PGHOST:$PGPORT/$PGDATABASE
raster2pgsql -d -C -s 4326 -t 100x100 ./data/PPT10_clip.tif data.climate_normals_ppt10 | psql postgresql://$PGUSER:$PGPASSWORD@$PGHOST:$PGPORT/$PGDATABASE
raster2pgsql -d -C -s 4326 -t 100x100 ./data/PPT11_clip.tif data.climate_normals_ppt11 | psql postgresql://$PGUSER:$PGPASSWORD@$PGHOST:$PGPORT/$PGDATABASE
raster2pgsql -d -C -s 4326 -t 100x100 ./data/PPT12_clip.tif data.climate_normals_ppt12 | psql postgresql://$PGUSER:$PGPASSWORD@$PGHOST:$PGPORT/$PGDATABASE

rm ./data/PPT*

psql postgres://$PGUSER:$PGPASSWORD@$PGHOST:$PGPORT/$PGDATABASE -v ON_ERROR_STOP=1 -f setup/sql/seed_tables.sql

