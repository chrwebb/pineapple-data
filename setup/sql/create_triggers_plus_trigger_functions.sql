-- data.assets triggers: 
-- trigger function
CREATE OR REPLACE FUNCTION data.fn_geo_update_event() RETURNS trigger AS 
  $BODY$  
  BEGIN
  -- as this is an after trigger, NEW contains all the information we need even for INSERT
  NEW.geom4326 =  ST_SetSRID(ST_MakePoint(NEW.longitude,NEW.latitude), 4326);
  NEW.created = now() at time zone 'utc';
  RAISE NOTICE 'UPDATING geom4326 field for asset_id: %, asset_name: %, [%,%]' , NEW.asset_id, NEW.asset_name, NEW.latitude, NEW.longitude; 
    RETURN NEW; 
  END;
 $BODY$
LANGUAGE plpgsql VOLATILE
COST 100;

CREATE OR REPLACE FUNCTION data.assets_insert_timezone() RETURNS trigger AS
  $BODY$
  BEGIN
  NEW.time_zone = tzid FROM data.timezone WHERE ST_Intersects(NEW.geom4326,geom4326);
  RAISE NOTICE 'UPDATING timezone for asset_id: %, asset_name:%,[%,%]', NEW.asset_id, NEW.asset_name, NEW.latitude, NEW.longitude;
    RETURN NEW;
  END;
  $BODY$
LANGUAGE plpgsql VOLATILE
COST 100;


CREATE OR REPLACE FUNCTION data.sentinels_insert_timezone() RETURNS trigger AS
  $BODY$
  BEGIN
  NEW.time_zone = tzid FROM data.timezone WHERE ST_Intersects(NEW.geom4326,geom4326);
  RAISE NOTICE 'UPDATING timezone for sentinel_id: %, station_id: %, station_name: %,[%,%]', NEW.sentinel_id, NEW.station_id, NEW.station_name, NEW.latitude, NEW.longitude;
    RETURN NEW;
  END;
  $BODY$
LANGUAGE plpgsql VOLATILE
COST 100;



CREATE OR REPLACE FUNCTION data.fn_fire_road_update_event() RETURNS trigger AS 
  $BODY$  
  BEGIN
  NEW.fire_past_2_years_m2 = ST_Area(ST_Intersection(NEW.aoi_geom4326,(SELECT ST_Union(geom4326) FROM data.fire_polygons WHERE fire_year>date_part('year', CURRENT_DATE)-2))::geography);
  NEW.fire_past_5_years_m2 = ST_Area(ST_Intersection(NEW.aoi_geom4326,(SELECT ST_Union(geom4326) FROM data.fire_polygons WHERE fire_year>date_part('year', CURRENT_DATE)-5))::geography);
  NEW.length_of_roads_m = ST_Length(ST_Intersection(NEW.aoi_geom4326,(SELECT ST_Union(geom4326) FROM data.road_lines WHERE ST_Intersects(NEW.aoi_geom4326,geom4326)))::geography);
  NEW.land_disturbance_fire =
    CASE 
      WHEN (NEW.fire_past_2_years_m2/NEW.aoi_area_m2)>0.15 THEN 2
      WHEN (NEW.fire_past_5_years_m2/NEW.aoi_area_m2)>0.20 THEN 2
      WHEN (NEW.fire_past_2_years_m2/NEW.aoi_area_m2)>0.10 THEN 1
      WHEN (NEW.fire_past_5_years_m2/NEW.aoi_area_m2)>0.15 THEN 1
      ELSE 0
    END;
  NEW.land_disturbance_road =
    CASE 
      WHEN (NEW.length_of_roads_m/NEW.aoi_area_m2)>2.5 THEN 2
      WHEN (NEW.length_of_roads_m/NEW.aoi_area_m2)>1.5 THEN 1
      ELSE 0
    END;
  NEW.created = now() at time zone 'utc';
  RAISE NOTICE 'UPDATING fire_past_2_years_m2, fire_past_5_years_m2, length_of_roads_m, land_disturbance_fire, land_disturbance_road field for asset_id: %, asset_name: %, [%,%]' , NEW.asset_id, NEW.asset_name, NEW.latitude, NEW.longitude; 
    RETURN NEW; 
  END;
 $BODY$
LANGUAGE plpgsql VOLATILE
COST 100;  

CREATE OR REPLACE FUNCTION data.fn_watershed_elev_update_event() RETURNS trigger AS
  $BODY$  
  BEGIN  
  NEW.aoi_elev_max_m = 
    CASE
      WHEN (ST_SummaryStats(ST_Clip(ST_Union((SELECT ST_Union(rast) FROM data.dem_bc WHERE ST_Intersects(rast, NEW.aoi_geom4326))), NEW.aoi_geom4326))).max=Null THEN (SELECT ST_Value(rast, ST_Centroid(NEW.aoi_geom4326)) FROM data.dem_bc WHERE ST_Intersects(rast, NEW.aoi_geom4326))
      ELSE (ST_SummaryStats(ST_Clip(ST_Union((SELECT ST_Union(rast) FROM data.dem_bc WHERE ST_Intersects(rast, NEW.aoi_geom4326))), NEW.aoi_geom4326))).max
    END; 
  NEW.aoi_elev_mean_m = 
    CASE
      WHEN (ST_SummaryStats(ST_Clip(ST_Union((SELECT ST_Union(rast) FROM data.dem_bc WHERE ST_Intersects(rast, NEW.aoi_geom4326))), NEW.aoi_geom4326))).mean=Null THEN (SELECT ST_Value(rast, ST_Centroid(NEW.aoi_geom4326)) FROM data.dem_bc WHERE ST_Intersects(rast, NEW.aoi_geom4326))
      ELSE (ST_SummaryStats(ST_Clip(ST_Union((SELECT ST_Union(rast) FROM data.dem_bc WHERE ST_Intersects(rast, NEW.aoi_geom4326))), NEW.aoi_geom4326))).mean
    END; 
  NEW.aoi_elev_min_m = 
    CASE
      WHEN (ST_SummaryStats(ST_Clip(ST_Union((SELECT ST_Union(rast) FROM data.dem_bc WHERE ST_Intersects(rast, NEW.aoi_geom4326))), NEW.aoi_geom4326))).min=Null THEN (SELECT ST_Value(rast, ST_Centroid(NEW.aoi_geom4326)) FROM data.dem_bc WHERE ST_Intersects(rast, NEW.aoi_geom4326))
      ELSE (ST_SummaryStats(ST_Clip(ST_Union((SELECT ST_Union(rast) FROM data.dem_bc WHERE ST_Intersects(rast, NEW.aoi_geom4326))), NEW.aoi_geom4326))).min
    END; 
  NEW.metadata='{"elev_masl_data_source": "Populated with DEM"}'::json;
  RAISE NOTICE 'UPDATING aoi_elev_max_m, aoi_elev_min_m, aoi_elev_mean_m, metadata field for asset_id: %, asset_name: %, [%,%]' , NEW.asset_id, NEW.asset_name, NEW.latitude, NEW.longitude; 
    RETURN NEW; 
  END;
 $BODY$
LANGUAGE plpgsql VOLATILE
COST 100;

CREATE OR REPLACE FUNCTION data.fn_sentinel_elev_update_event() RETURNS trigger AS
  $BODY$  
  BEGIN
  NEW.elevation_m=(SELECT ST_Value(rast, ST_Centroid(NEW.geom4326)) FROM data.dem_bc WHERE ST_Intersects(rast, NEW.geom4326));
  NEW.metadata='{"elev_masl_data_source": "Populated with DEM"}'::json;
  RAISE NOTICE 'UPDATING elevation_m, metadata field for station_name: %, station_name: %, [%,%]' , NEW.station_name, NEW.station_name, NEW.latitude, NEW.longitude; 
    RETURN NEW; 
  END;
 $BODY$
LANGUAGE plpgsql VOLATILE
COST 100;

-- triggers
-- INSERT geo trigger
DROP TRIGGER IF EXISTS assets_table_inserted_geo ON data.assets;
CREATE TRIGGER assets_table_inserted_geo
  BEFORE INSERT ON data.assets
  FOR EACH ROW
  EXECUTE PROCEDURE data.fn_geo_update_event();

--  UPDATE geo trigger
DROP TRIGGER IF EXISTS assets_table_geo_updated ON data.assets;
CREATE TRIGGER assets_table_geo_updated
  AFTER UPDATE OF 
  latitude,
  longitude
  ON data.assets
  FOR EACH ROW
  EXECUTE PROCEDURE data.fn_geo_update_event();

-- INSERT land use trigger
DROP TRIGGER IF EXISTS asset_table_insert_fire_road ON data.assets;
CREATE TRIGGER asset_table_insert_fire_road
  BEFORE INSERT ON data.assets
  FOR EACH ROW
  EXECUTE PROCEDURE data.fn_fire_road_update_event();

-- INSERT watershed elev asset trigger
DROP TRIGGER IF EXISTS asset_table_insert_watershed_elev ON data.assets;
CREATE TRIGGER asset_table_insert_watershed_elev
  BEFORE INSERT ON data.assets
  FOR EACH ROW
  WHEN (NEW.aoi_elev_min_m=-1 OR NEW.aoi_elev_max_m=-1 OR NEW.aoi_elev_mean_m=-1)
  EXECUTE PROCEDURE data.fn_watershed_elev_update_event();

-- UPDATE watershed elev asset trigger
DROP TRIGGER IF EXISTS asset_table_update_watershed_elev ON data.assets;
CREATE TRIGGER asset_table_update_watershed_elev
  BEFORE UPDATE OF 
  aoi_geom4326
  ON data.assets
  FOR EACH ROW
  WHEN (NEW.aoi_elev_min_m=-1 OR NEW.aoi_elev_max_m=-1 OR NEW.aoi_elev_mean_m=-1)
  EXECUTE PROCEDURE data.fn_watershed_elev_update_event();


-- INSERT sentinel elev asset trigger
DROP TRIGGER IF EXISTS sentinel_table_insert_elev ON data.sentinels;
CREATE TRIGGER sentinel_table_insert_elev
  BEFORE INSERT ON data.sentinels
  FOR EACH ROW
  WHEN (NEW.elevation_m=-1)
  EXECUTE PROCEDURE data.fn_sentinel_elev_update_event();

-- UPDATE sentinel elev asset trigger
DROP TRIGGER IF EXISTS sentinel_table_update_elev ON data.sentinels;
CREATE TRIGGER sentinel_table_update_elev
  BEFORE UPDATE OF 
  geom4326
  ON data.sentinels
  FOR EACH ROW
  WHEN (NEW.elevation_m=-1)
  EXECUTE PROCEDURE data.fn_sentinel_elev_update_event();

--INSERT timezone use trigger for assets table 
DROP TRIGGER IF EXISTS asset_table_insert_timezone ON data.assets;
CREATE TRIGGER asset_table_insert_timezone
  BEFORE INSERT ON data.assets
  FOR EACH ROW
  EXECUTE PROCEDURE data.assets_insert_timezone();

--INSERT timezone use trigger for sentinels table 
DROP TRIGGER IF EXISTS sentinel_table_insert_timezone ON data.sentinels;
CREATE TRIGGER sentinel_table_insert_timezone
  BEFORE INSERT ON data.sentinels
  FOR EACH ROW
  EXECUTE PROCEDURE data.sentinels_insert_timezone();