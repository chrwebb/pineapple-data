-- data.assets triggers: 
-- trigger function
CREATE OR REPLACE FUNCTION fn_geo_update_event() RETURNS trigger AS 
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

CREATE OR REPLACE FUNCTION fn_fire_road_update_event() RETURNS trigger AS 
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

-- triggers
-- INSERT geo trigger
DROP TRIGGER IF EXISTS assets_table_inserted_geo ON data.assets;
CREATE TRIGGER assets_table_inserted_geo
  BEFORE INSERT ON data.assets
  FOR EACH ROW
  EXECUTE PROCEDURE fn_geo_update_event();

--  UPDATE geo trigger
DROP TRIGGER IF EXISTS assets_table_geo_updated ON data.assets;
CREATE TRIGGER assets_table_geo_updated
  AFTER UPDATE OF 
  latitude,
  longitude
  ON data.assets
  FOR EACH ROW
  EXECUTE PROCEDURE fn_geo_update_event();

-- INSERT land use trigger
DROP TRIGGER IF EXISTS asset_table_insert_fire_road ON data.assets;
CREATE TRIGGER asset_table_insert_fire_road
  BEFORE INSERT ON data.assets
  FOR EACH ROW
  EXECUTE PROCEDURE fn_fire_road_update_event();