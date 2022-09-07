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

CREATE OR REPLACE FUNCTION data.get_fire_years
  (OUT fire_years_data json)
    RETURNS SETOF json 
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
    ROWS 1000
AS $BODY$
  BEGIN
      RETURN QUERY
      SELECT
      JSON_AGG(b)
      FROM
      (
        SELECT
      DISTINCT fire_year
    FROM
      data.fire_polygons
    ORDER BY fire_year DESC
    LIMIT 5
      )b;
  END
$BODY$;

CREATE OR REPLACE FUNCTION data.get_asset_forecast_dates
  (in_asset_id integer, 
  OUT forecast_date json)
    RETURNS SETOF json 
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
AS $BODY$
  BEGIN
      RETURN QUERY
        SELECT
      json_build_object('forecast', forecast_made_at_utc, 'next_forecast', forecast_made_at_utc + interval '12 hour')
    FROM
      data.assets_forecast
    WHERE
      asset_id=in_asset_id
    ORDER BY 
      forecast_made_at_utc DESC
    LIMIT 1;
  END
$BODY$;

CREATE OR REPLACE FUNCTION data.get_sentinel_info
  (in_sentinel_id integer, 
  OUT sentinel_info json)
    RETURNS SETOF json 
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
AS $BODY$
  BEGIN
      RETURN QUERY
      SELECT
      json_build_object(
        'station_name', station_name,
        'station_id', station_id
      )
    FROM
      data.sentinels
    WHERE
      sentinel_id=in_sentinel_id;
  END
$BODY$;

CREATE OR REPLACE FUNCTION data.get_sentinel_storms_of_record
  (in_sentinel_id integer, 
  OUT sentinel_storms_of_record json)
    RETURNS SETOF json 
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
AS $BODY$
  BEGIN
      RETURN QUERY
      SELECT
      json_build_object(
        'station_name', sentinel.station_name,
        'station_id', sentinel.station_id,
        'start_date', storm.storm_date,
        'end_date', storm.storm_date + storm.storm_duration * INTERVAL '1 day',
        'magnitude', storm.storm_magnitude
      )
    FROM
      data.sentinels_historic_storms storm
    JOIN
      data.sentinels sentinel
    ON
      storm.sentinel_id=sentinel.sentinel_id
    WHERE
      storm.sentinel_id=in_sentinel_id;
  END
$BODY$;

CREATE OR REPLACE FUNCTION data.get_asset_info
  (in_asset_id integer, 
  OUT asset_info json,
  OUT aoi_polygon geometry(Polygon, 4236))
    RETURNS SETOF record 
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
AS $BODY$
  BEGIN
      RETURN QUERY
        SELECT
      json_build_object(
        'asset_name', asset.asset_name,
        'asset_description', asset.asset_description,
        'parent_name', parent.parent_name,
        'forecast_date', forecast.forecast_date,
        'value', forecast.sum,
        'risk_level', forecast.risk_level--,
        --'return_period', return_period
      ),
      asset.aoi_geom4326
    FROM
      data.assets asset
    JOIN
      data.parents parent
    ON
      asset.parent_id=parent.parent_id
    JOIN
      (
        SELECT
          forecast_daily.asset_id,
          forecast_daily.forecast_date,
          sum, 
          risk_level--,
          --return_period
        FROM (
          SELECT 
            sum(value),
            forecast.forecast_3h_utc::date as forecast_date,
            forecast.asset_id
          FROM 
            data.assets_forecast forecast 
          JOIN 
            data.models model 
          ON 
            forecast.model_id=model.model_id 
          WHERE 
            forecast.asset_id=1 
          AND
            model.model_id=9
          GROUP BY 
            forecast_date, forecast.asset_id
          ) forecast_daily
        LEFT JOIN
          data.risk_levels risk
        ON
          (
            risk.lower_bound<=forecast_daily.sum
            AND
            risk.upper_bound>forecast_daily.sum
          )
          OR
          (
            risk.lower_bound<=forecast_daily.sum
            AND
            risk.upper_bound is Null
          )
          OR
          (
            risk.upper_bound>forecast_daily.sum
            AND
            risk.lower_bound is Null
          )
        ORDER BY
          risk_level DESC
        LIMIT 1
      ) forecast
    ON
      forecast.asset_id=asset.asset_id
    WHERE
        asset.asset_id=1;
  END
$BODY$;


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