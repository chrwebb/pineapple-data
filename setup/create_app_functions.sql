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



CREATE OR REPLACE FUNCTION data.asset_previous_forecast_made_at 
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

  ALTER FUNCTION data.asset_previous_forecast_made_at(integer) OWNER TO foundry;
  GRANT EXECUTE ON FUNCTION data.asset_previous_forecast_made_at(integer) TO foundry;

CREATE OR REPLACE FUNCTION data.sentinel_previous_forecast_made_at 
(
  in_sentinel_id integer,
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
		data.sentinels_forecast
	  WHERE 
	  sentinel_id = in_sentinel_id
	ORDER BY 
		forecast_made_at DESC
	LIMIT 1;
  END
  $BODY$;

  ALTER FUNCTION data.sentinel_previous_forecast_made_at(integer) OWNER TO foundry;
  GRANT EXECUTE ON FUNCTION data.sentinel_previous_forecast_made_at(integer) TO foundry;

--stored_procedure_for_current_forecast

CREATE OR REPLACE FUNCTION data.asset_current_forecast_made_at 
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

  ALTER FUNCTION data.asset_current_forecast_made_at(integer) OWNER TO foundry;
  GRANT EXECUTE ON FUNCTION data.asset_current_forecast_made_at(integer) TO foundry;


CREATE OR REPLACE FUNCTION data.sentinel_current_forecast_made_at 
(
  in_sentinel_id integer,
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
		data.sentinels_forecast
	  WHERE 
	  sentinel_id = in_sentinel_id
	ORDER BY 
		forecast_made_at DESC
	LIMIT 1;
  END
  $BODY$;

  ALTER FUNCTION data.sentinel_current_forecast_made_at(integer) OWNER TO foundry;
  GRANT EXECUTE ON FUNCTION data.sentinel_current_forecast_made_at(integer) TO foundry;

-- stored procedure for current forecast plus previous 12 hours 

CREATE OR REPLACE FUNCTION data.get_asset_current_plus_previous_24hours_forecast
(
	in_asset_id integer,
	OUT asset_id integer,
	OUT forecast_made_at timestamp with time zone,
	OUT forecast_1h_local timestamp without time zone,
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
		VALUES (in_asset_id, (SELECT data.asset_current_forecast_made_at(in_asset_id)), (SELECT data.asset_previous_forecast_made_at(in_asset_id)))
		)
		SELECT
			a.asset_id, a.forecast_made_at, a.forecast_1h at time zone assets.time_zone as forecast_1h_local, a.value
		FROM
			constants
		JOIN
			data.assets assets
		USING 
			(asset_id)
		JOIN
			data.assets_forecast a
		on
			a.forecast_made_at = constants.previous_forecast_made_at - INTERVAL '12 hour'
		WHERE
			a.forecast_1h < constants.previous_forecast_made_at
		AND
			a.model_id = 9
		UNION
		SELECT
			a.asset_id, a.forecast_made_at, a.forecast_1h at time zone assets.time_zone as forecast_1h_local, a.value
		FROM
			constants
		JOIN
			data.assets assets
		USING 
			(asset_id)
		JOIN
			data.assets_forecast a
		on
			a.forecast_made_at = constants.previous_forecast_made_at
		WHERE
			a.forecast_1h < constants.current_forecast_made_at
		AND
			a.model_id = 9
		UNION 
		SELECT
			a.asset_id, a.forecast_made_at, a.forecast_1h at time zone assets.time_zone as forecast_1h_local, a.value
		FROM
			constants
		JOIN
			data.assets assets
		USING 
			(asset_id)
		JOIN
			data.assets_forecast a
		on
			a.forecast_made_at = constants.current_forecast_made_at
		WHERE
			a.model_id = 9
		ORDER BY 
			asset_id, forecast_1h_local;
	END
	$BODY$;


CREATE OR REPLACE FUNCTION data.get_sentinel_current_plus_previous_24hours_forecast
(
	in_sentinel_id integer,
	OUT sentinel_id integer,
	OUT forecast_made_at timestamp with time zone,
	OUT forecast_1h_local timestamp without time zone,
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
		WITH constants (sentinel_id, current_forecast_made_at, previous_forecast_made_at) as (
			VALUES (in_sentinel_id, (SELECT data.sentinel_current_forecast_made_at(in_sentinel_id)), (SELECT data.sentinel_previous_forecast_made_at(in_sentinel_id)))
			)
		SELECT
			a.sentinel_id, a.forecast_made_at, a.forecast_1h at time zone sentinels.time_zone as forecast_1h_local, a.value
		FROM
			constants
		JOIN
			data.sentinels sentinels
		USING 
			(sentinel_id)
		JOIN
			data.sentinels_forecast a
		on
			a.forecast_made_at = constants.previous_forecast_made_at - INTERVAL '12 hour'
		WHERE
			a.forecast_1h < constants.previous_forecast_made_at
		AND
			a.model_id = 9
		UNION
		SELECT
			a.sentinel_id, a.forecast_made_at, a.forecast_1h at time zone sentinels.time_zone as forecast_1h_local, a.value
		FROM
			constants
		JOIN
			data.sentinels sentinels
		USING 
			(sentinel_id)
		JOIN
			data.sentinels_forecast a
		on
			a.forecast_made_at = constants.previous_forecast_made_at
		WHERE
			a.forecast_1h < constants.current_forecast_made_at
		AND
			a.model_id = 9
		UNION 
		SELECT
			a.sentinel_id, a.forecast_made_at, a.forecast_1h at time zone sentinels.time_zone as forecast_1h_local, a.value
		FROM
			constants
		JOIN
			data.sentinels sentinels
		USING 
			(sentinel_id)
		JOIN
			data.sentinels_forecast a
		ON
			a.forecast_made_at = constants.current_forecast_made_at
		WHERE
			a.model_id = 9
		ORDER BY 
			sentinel_id,forecast_1h_local;
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