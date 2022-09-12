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



CREATE OR REPLACE FUNCTION data.previous_forecast_made_at 
(
  in_asset_id integer,
  OUT previous_forecast_made_at timestamp with time zone
)
  RETURNS SETOF timestamp with time zone
  LANGUAGE 'plpgsql'

  COST 100
  VOLATILE
  ROWS 1
AS $BODY$
  BEGIN 
      RETURN QUERY
      SELECT 
        forecast_made_at - INTERVAL '12 hour' as previous_forecast_made_at 
      FROM
        data.assets_forecast
      WHERE 
      asset_id = in_asset_id
    ORDER BY 
        forecast_made_at DESC
    LIMIT 1;
  END
  $BODY$;

  ALTER FUNCTION data.previous_forecast_made_at(integer) OWNER TO foundry;
  GRANT EXECUTE ON FUNCTION data.previous_forecast_made_at(integer) TO foundry;

--stored_procedure_for_current_forecast

CREATE OR REPLACE FUNCTION data.current_forecast_made_at 
(
  in_asset_id integer,
  OUT previous_forecast_made_at timestamp with time zone 
)
  RETURNS SETOF timestamp with time zone
  LANGUAGE 'plpgsql'

  COST 100
  VOLATILE
  ROWS 1
AS $BODY$
  BEGIN 
      RETURN QUERY
      SELECT 
        forecast_made_at as current_forecast_made_at 
      FROM
        data.assets_forecast
      WHERE 
      asset_id = in_asset_id
    ORDER BY 
        forecast_made_at DESC
    LIMIT 1;
  END
  $BODY$;

  ALTER FUNCTION data.current_forecast_made_at(integer) OWNER TO foundry;
  GRANT EXECUTE ON FUNCTION data.current_forecast_made_at(integer) TO foundry;

-- stored procedure for asset forecast dates

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
      json_build_object('forecast', forecast_made_at, 'next_forecast', forecast_made_at + interval '12 hour')
    FROM
      data.assets_forecast
    WHERE
      asset_id=in_asset_id
    ORDER BY 
      forecast_made_at DESC
    LIMIT 1;
  END
$BODY$;

-- stored procedure for current forecast plus previous 12 hours 

CREATE OR REPLACE FUNCTION data.get_current_plus_previous_12hours_forecast
(
  in_asset_id integer,
  OUT asset_id integer,
  OUT forecast_made_at timestamp with time zone,
  OUT forecast_1h timestamp with time zone,
  OUT model_id integer,
  OUT value double precision
)
  RETURNS SETOF RECORD
  LANGUAGE 'plpgsql'
  COST 100
  VOLATILE
  ROWS 10000
AS $BODY$
    BEGIN
      RETURN QUERY
      WITH constants (asset_id, current_forecast_made_at, previous_forecast_made_at) as (
          VALUES (1, (SELECT data.current_forecast_made_at(1)), (SELECT data.previous_forecast_made_at(1)))
          )
          SELECT
            a.*
          FROM
            constants
          JOIN
            data.assets_forecast a
          on
            a.forecast_made_at = constants.previous_forecast_made_at - INTERVAL '12 hour'
          WHERE
            a.forecast_1h < (SELECT data.previous_forecast_made_at(1))
          UNION
          SELECT
            a.*
          FROM
            constants
          JOIN
            data.assets_forecast a
          on
            a.forecast_made_at = constants.previous_forecast_made_at
          WHERE
            a.forecast_1h < (SELECT data.current_forecast_made_at(1))
          UNION 
          SELECT
            a.*
          FROM
            constants
          JOIN
            data.assets_forecast a
          on
            a.forecast_made_at = constants.current_forecast_made_at
          ORDER BY 
            asset_id,model_id,forecast_1h;
    END
    $BODY$;

  ALTER FUNCTION data.get_current_plus_previous_12hours_forecast(integer) OWNER TO foundry;
  GRANT EXECUTE ON FUNCTION data.get_current_plus_previous_12hours_forecast(integer) TO foundry;



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
        'start_date', storm.storm_start_date,
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
            'forecast_date', risk_level.hr24_risk_level,
            'risk_level', risk_level.hr24_storm_start_date
          ),
          asset.aoi_geom4326
        FROM
          data.assets asset
        JOIN 
          (
            SELECT
              asset.asset_id,
              asset_forecast.forecast_3h::date as hr24_storm_start_date,
              CASE
                WHEN sum(asset_forecast.value)<avg(hr24_5yr) THEN 1
                WHEN sum(asset_forecast.value)>=avg(hr24_5yr) AND sum(asset_forecast.value)<avg(hr24_10yr) THEN 2
                WHEN sum(asset_forecast.value)>=avg(hr24_10yr) AND sum(asset_forecast.value)<avg(hr24_50yr) THEN 3
                WHEN sum(asset_forecast.value)>=avg(hr24_50yr) AND sum(asset_forecast.value)<avg(hr24_100yr) THEN 4
                WHEN sum(asset_forecast.value)>=avg(hr24_100yr) THEN 5
              END as hr24_risk_level
            FROM
              data.assets asset
            JOIN
              data.pf_grids_aep_rollup aep
            ON
              asset.watershed_feature_id=aep.watershed_feature_id
            JOIN
              data.assets_forecast asset_forecast
            ON
              asset.asset_id=asset_forecast.asset_id
            WHERE
              asset.asset_id=in_asset_id
            AND
              asset_forecast.model_id=9
            GROUP BY
              asset_forecast.forecast_3h::date,
              asset.asset_id
            ORDER BY
              hr24_risk_level DESC
            LIMIT 1
          ) risk_level
        ON
          asset.asset_id=risk_level.asset_id
        JOIN
          data.parents parent
        ON
          asset.parent_id=parent.parent_id
        WHERE
          asset.asset_id=in_asset_id;
  END
$BODY$;

-- stored procedure for get_asset_antecedent_rain()
CREATE OR REPLACE FUNCTION data.get_asset_antecedent_rain(
  in_asset_id integer,
  OUT antecedant_data json
)
  RETURNS SETOF json
  LANGUAGE 'plpgsql'

  COST 100
  VOLATILE
  ROWS 1
AS $BODY$
  BEGIN 
      RETURN QUERY
      SELECT 
      row_to_json(b)
    FROM(
       SELECT
          a.seven_day,
          a.thirty_day,
          a.seven_day_pct_normal,
          a.thirty_day_pct_normal
        FROM
          data.assets_antecedant a
        WHERE
          asset_id = in_asset_id
        ORDER BY 
          created DESC
        LIMIT 1
        )b;
  END
  $BODY$;

  ALTER FUNCTION data.get_asset_antecedent_rain(integer) OWNER TO foundry;
  GRANT EXECUTE ON FUNCTION data.get_asset_antecedent_rain(integer) TO foundry;


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

--INSERT timezone use trigger for assets table 
DROP TRIGGER IF EXISTS asset_table_insert_timezone ON data.assets;
CREATE TRIGGER asset_table_insert_timezone
  BEFORE INSERT ON data.assets
  FOR EACH ROW
  EXECUTE PROCEDURE data.assets_insert_timezone();

--INSERT timezone use trigger for sentinels table 
DROP TRIGGER IF EXISTS sentinel_table_insert_timezone ON data.seninels;
CREATE TRIGGER asset_table_insert_timezone
  BEFORE INSERT ON data.sentinels
  FOR EACH ROW
  EXECUTE PROCEDURE data.sentinels_insert_timezone();