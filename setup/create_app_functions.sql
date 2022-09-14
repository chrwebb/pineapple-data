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
		'end_date', storm.storm_start_date + storm.storm_duration * INTERVAL '1 day',
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
		  	'group_name', parent.group_name,
			'asset_name', asset.asset_name,
			'asset_description', asset.asset_description,
			'risk_level',risk_level.risk
		  ),
		  asset.aoi_geom4326
		FROM
		  data.assets asset
		JOIN 
		  (
			SELECT
			  asset.asset_id,
			  asset.asset_name,
			  risk.risk
			FROM
			  data.assets asset
			JOIN
			  (SELECT asset_id,max(risk_level) as risk from data.get_asset_one_and_two_day_current_forecast_risk_level(in_asset_id) group by asset_id) risk
			USING
			  (asset_id)
			WHERE
			  asset.asset_id=in_asset_id
			GROUP BY
			  asset.asset_id,risk.risk
		  ) risk_level
		  
		USING
			(asset_id)
		JOIN
		  data.groups parent
		ON
		  asset.group_id=parent.group_id
		WHERE
		  asset.asset_id=in_asset_id;
  END
$BODY$;


-- stored procedure for getting 3 hour rainfall buckets for assets 
CREATE OR REPLACE FUNCTION data.get_asset_3hr_buckets(
  in_asset_id integer,
  OUT asset_id integer,
  OUT forecast_made_at timestamp with time zone,
  OUT forecast_1h_local timestamp without time zone,
  OUT value_3h double precision
)
  RETURNS SETOF RECORD
  LANGUAGE 'plpgsql'

  COST 100
  VOLATILE
  ROWS 100
AS $BODY$
  BEGIN
  	RETURN QUERY
  	with hourly_data as(  
  		SELECT
  			full_data.asset_id, 
			full_data.forecast_made_at,
			full_data.forecast_1h_local,
			full_data.value
  		FROM
  			(select * from data.get_asset_current_plus_previous_24hours_forecast(in_asset_id)) full_data
		WHERE
			full_data.asset_id = in_asset_id
		),
		a as (
			SELECT
				b.asset_id, 
				b.forecast_made_at,
				b.forecast_1h_local,
				SUM(b.value) OVER (ORDER BY b.asset_id,b.forecast_made_at,b.forecast_1h_local
                      ROWS BETWEEN CURRENT ROW AND 2 FOLLOWING) AS value_3h,
				extract (hour from b.forecast_1h_local) as hour
			FROM 
				hourly_data b
			ORDER BY
				asset_id,forecast_made_at,forecast_1h_local
			)
	SELECT
		a.asset_id,
		a.forecast_made_at,
		a.forecast_1h_local,
		a.value_3h
	FROM
		a
	WHERE
		a.asset_id = in_asset_id
	AND 
		hour in (12,15,18,21,0,3,6,9)
	AND 
		a.forecast_1h_local::date >= (SELECT data.asset_current_forecast_made_at(in_asset_id)::date);
  END
  $BODY$;


-- stored procedure for getting 3 hour rainfall buckets for sentinels 
CREATE OR REPLACE FUNCTION data.get_sentinel_3hr_buckets(
  in_sentinel_id integer,
  OUT sentinel_id integer,
  OUT forecast_made_at timestamp with time zone,
  OUT forecast_1h_local timestamp without time zone,
  OUT value_3h double precision
)
  RETURNS SETOF RECORD
  LANGUAGE 'plpgsql'

  COST 100
  VOLATILE
  ROWS 100
AS $BODY$
  BEGIN
  	RETURN QUERY
  	with hourly_data as(  
  		SELECT
  			full_data.sentinel_id, 
			full_data.forecast_made_at,
			full_data.forecast_1h_local,
			full_data.value
  		FROM
  			(select * from data.get_sentinel_current_plus_previous_24hours_forecast(in_sentinel_id)) full_data
		WHERE
			full_data.sentinel_id = in_sentinel_id
		),
		a as (
			SELECT
				b.sentinel_id, 
				b.forecast_made_at,
				b.forecast_1h_local,
				SUM(b.value) OVER (ORDER BY b.sentinel_id,b.forecast_made_at,b.forecast_1h_local
                      ROWS BETWEEN CURRENT ROW AND 2 FOLLOWING) AS value_3h,
				extract (hour from b.forecast_1h_local) as hour
			FROM 
				hourly_data b
			ORDER BY
				sentinel_id,forecast_made_at,forecast_1h_local
			)
	SELECT
		a.sentinel_id,
		a.forecast_made_at,
		a.forecast_1h_local,
		a.value_3h
	FROM
		a
	WHERE
		a.sentinel_id = in_sentinel_id
	AND 
		hour in (12,15,18,21,0,3,6,9)
	AND 
		a.forecast_1h_local::date >= (SELECT data.sentinel_current_forecast_made_at(in_sentinel_id)::date);
  END
  $BODY$;

-- stored procedure for risk levels of assets for current forecasts 
CREATE OR REPLACE FUNCTION data.get_asset_one_and_two_day_current_forecast_risk_level(
	in_asset_id integer,
	OUT asset_id integer,
	OUT dt date,
	OUT one_day double precision,
	OUT two_day double precision,
	OUT risk_level_one_day integer,
	OUT risk_level_two_day integer,
	OUT risk_level integer
)
	RETURNS SETOF RECORD
	LANGUAGE 'plpgsql'

	COST 100
	VOLATILE
	ROWS 10
AS $BODY$
	BEGIN
		RETURN QUERY
		with hourly_rainfall as(
	SELECT
  	 	a.asset_id, 
		a.forecast_made_at,
		a.forecast_1h_local,
		a.value
  	FROM
  		data.get_asset_current_plus_previous_24hours_forecast(in_asset_id) a
), per_day as (
		SELECT
			b.asset_id,
			c.watershed_feature_id,
			b.forecast_1h_local::date as dt,
			sum(b.value) as one_day
		FROM
			hourly_rainfall b
		JOIN
			data.assets c
		USING
			(asset_id)
		WHERE
			b.asset_id = in_asset_id
		GROUP BY 
			b.forecast_1h_local::date, 
			b.asset_id,
			watershed_feature_id
			), per24_48 as (
					SELECT
						per_day.*,
						sum(per_day.one_day) over (ORDER BY per_day.dt
	   						rows between current row and 1 following) as two_day
					FROM
						per_day
			)
			SELECT
				per24_48.asset_id,
				per24_48.dt,
				per24_48.one_day,
				per24_48.two_day,
			CASE
				WHEN  per24_48.one_day <= hr24_5yr THEN 1
				WHEN  per24_48.one_day > hr24_5yr AND per24_48.one_day <= hr24_10yr THEN 2
				WHEN  per24_48.one_day > hr24_10yr AND per24_48.one_day <= hr24_50yr THEN 3
				WHEN  per24_48.one_day > hr24_50yr AND per24_48.one_day <= hr24_100yr THEN 4
				WHEN  per24_48.one_day > hr24_100yr THEN 5
			END AS
			risk_level_one_day,
			CASE
				WHEN  per24_48.two_day <= hr48_5yr THEN 1
				WHEN  per24_48.two_day > hr48_5yr AND per24_48.two_day <= hr48_10yr THEN 2
				WHEN  per24_48.two_day > hr48_10yr AND per24_48.two_day <= hr48_50yr THEN 3
				WHEN  per24_48.two_day > hr48_50yr AND per24_48.two_day <= hr48_100yr THEN 4
				WHEN  per24_48.two_day > hr48_100yr THEN 5
			END AS
			risk_level_two_day,
			GREATEST(
			CASE
				WHEN  per24_48.one_day <= hr24_5yr THEN 1
				WHEN  per24_48.one_day > hr24_5yr AND per24_48.one_day <= hr24_10yr THEN 2
				WHEN  per24_48.one_day > hr24_10yr AND per24_48.one_day <= hr24_50yr THEN 3
				WHEN  per24_48.one_day > hr24_50yr AND per24_48.one_day <= hr24_100yr THEN 4
				WHEN  per24_48.one_day > hr24_100yr THEN 5
				END, 
			CASE
				WHEN  per24_48.two_day <= hr48_5yr THEN 1
				WHEN  per24_48.two_day > hr48_5yr AND per24_48.two_day <= hr48_10yr THEN 2
				WHEN  per24_48.two_day > hr48_10yr AND per24_48.two_day <= hr48_50yr THEN 3
				WHEN  per24_48.two_day > hr48_50yr AND per24_48.two_day <= hr48_100yr THEN 4
				WHEN  per24_48.two_day > hr48_100yr THEN 5
			END) as risk_level
			from
				per24_48
			JOIN
				data.pf_grids_aep_rollup r
			USING
				(watershed_feature_id)
			WHERE 
				per24_48.asset_id = in_asset_id
			AND 
				per24_48.dt >= (SELECT data.asset_current_forecast_made_at(in_asset_id)::date)
			ORDER BY asset_id,dt;
	END
	$BODY$;

-- stored procedure for risk levels of assets for previous forecasts 
CREATE OR REPLACE FUNCTION data.get_asset_one_and_two_day_previous_forecast_risk_level(
	in_asset_id integer,
	OUT asset_id integer,
	OUT dt date,
	OUT one_day double precision,
	OUT two_day double precision,
	OUT risk_level_one_day integer,
	OUT risk_level_two_day integer,
	OUT risk_level integer
)
	RETURNS SETOF RECORD
	LANGUAGE 'plpgsql'

	COST 100
	VOLATILE
	ROWS 10
AS $BODY$
	BEGIN
		RETURN QUERY
		with hourly_rainfall as(	
SELECT
  	 	a.asset_id, 
		a.forecast_made_at,
		a.forecast_1h,
		a.value
  	FROM
  		data.assets_forecast a
  	WHERE
  		a.forecast_made_at = (SELECT data.asset_previous_forecast_made_at(in_asset_id))
  	and
  		a.model_id = 9 
), per_day as (
		SELECT
			b.asset_id,
			c.watershed_feature_id,
			b.forecast_1h::date as dt,
			sum(b.value) as one_day
		FROM
			hourly_rainfall b
		JOIN
			data.assets c
		USING
			(asset_id)
		WHERE
			b.asset_id = in_asset_id
		GROUP BY 
			b.forecast_1h::date, 
			b.asset_id,
			watershed_feature_id
			), per24_48 as (
					SELECT
						per_day.*,
						sum(per_day.one_day) over (ORDER BY per_day.dt
	   						rows between current row and 1 following) as two_day
					FROM
						per_day
			)
			SELECT
				per24_48.asset_id,
				per24_48.dt,
				per24_48.one_day,
				per24_48.two_day,
			CASE
				WHEN  per24_48.one_day <= hr24_5yr THEN 1
				WHEN  per24_48.one_day > hr24_5yr AND per24_48.one_day <= hr24_10yr THEN 2
				WHEN  per24_48.one_day > hr24_10yr AND per24_48.one_day <= hr24_50yr THEN 3
				WHEN  per24_48.one_day > hr24_50yr AND per24_48.one_day <= hr24_100yr THEN 4
				WHEN  per24_48.one_day > hr24_100yr THEN 5
			END AS
			risk_level_one_day,
			CASE
				WHEN  per24_48.two_day <= hr48_5yr THEN 1
				WHEN  per24_48.two_day > hr48_5yr AND per24_48.two_day <= hr48_10yr THEN 2
				WHEN  per24_48.two_day > hr48_10yr AND per24_48.two_day <= hr48_50yr THEN 3
				WHEN  per24_48.two_day > hr48_50yr AND per24_48.two_day <= hr48_100yr THEN 4
				WHEN  per24_48.two_day > hr48_100yr THEN 5
			END AS
			risk_level_two_day,
			GREATEST(
			CASE
				WHEN  per24_48.one_day <= hr24_5yr THEN 1
				WHEN  per24_48.one_day > hr24_5yr AND per24_48.one_day <= hr24_10yr THEN 2
				WHEN  per24_48.one_day > hr24_10yr AND per24_48.one_day <= hr24_50yr THEN 3
				WHEN  per24_48.one_day > hr24_50yr AND per24_48.one_day <= hr24_100yr THEN 4
				WHEN  per24_48.one_day > hr24_100yr THEN 5
				END, 
			CASE
				WHEN  per24_48.two_day <= hr48_5yr THEN 1
				WHEN  per24_48.two_day > hr48_5yr AND per24_48.two_day <= hr48_10yr THEN 2
				WHEN  per24_48.two_day > hr48_10yr AND per24_48.two_day <= hr48_50yr THEN 3
				WHEN  per24_48.two_day > hr48_50yr AND per24_48.two_day <= hr48_100yr THEN 4
				WHEN  per24_48.two_day > hr48_100yr THEN 5
			END) as risk_level
			from
				per24_48
			JOIN
				data.pf_grids_aep_rollup r
			USING
				(watershed_feature_id)
			WHERE 
				per24_48.asset_id = in_asset_id
			AND 
				per24_48.dt >= (SELECT data.asset_current_forecast_made_at(in_asset_id)::date)
			ORDER BY asset_id,dt;
	END
	$BODY$;

-- stored procedure for risk levels of sentinels for current forecasts 
CREATE OR REPLACE FUNCTION data.get_sentinel_one_and_two_day_current_forecast_risk_level(
	in_sentinel_id integer,
	OUT sentinel_id integer,
	OUT dt date,
	OUT one_day double precision,
	OUT two_day double precision,
	OUT risk_level_one_day integer,
	OUT risk_level_two_day integer,
	OUT risk_level integer
)
	RETURNS SETOF RECORD
	LANGUAGE 'plpgsql'

	COST 100
	VOLATILE
	ROWS 10
AS $BODY$
	BEGIN
		RETURN QUERY
		with hourly_rainfall as(
	SELECT
  	 	a.sentinel_id, 
		a.forecast_made_at,
		a.forecast_1h_local,
		a.value
  	FROM
  		data.get_sentinel_current_plus_previous_24hours_forecast(in_sentinel_id) a
), per_day as (
		SELECT
			c.sentinel_id,
			c.hr24_5yr,
			c.hr24_10yr,
			c.hr24_20yr,
			c.hr24_50yr,
			c.hr24_100yr,
			c.hr48_5yr,
			c.hr48_10yr,
			c.hr48_20yr,
			c.hr48_50yr,
			c.hr48_100yr,
			b.forecast_1h_local::date as dt,
			sum(b.value) as one_day
		FROM
			hourly_rainfall b
		JOIN
			data.sentinels c
		USING
			(sentinel_id)
		WHERE
			b.sentinel_id = in_sentinel_id
		GROUP BY 
			b.forecast_1h_local::date, 
			c.sentinel_id,
			c.hr24_5yr,
			c.hr24_10yr,
			c.hr24_20yr,
			c.hr24_50yr,
			c.hr24_100yr,
			c.hr48_5yr,
			c.hr48_10yr,
			c.hr48_20yr,
			c.hr48_50yr,
			c.hr48_100yr
			), per24_48 as (
					SELECT
						per_day.*,
						sum(per_day.one_day) over (ORDER BY per_day.dt
	   						rows between current row and 1 following) as two_day
					FROM
						per_day
			)
			SELECT
				per24_48.sentinel_id,
				per24_48.dt,
				per24_48.one_day,
				per24_48.two_day,
			CASE
				WHEN  per24_48.one_day <= per_day.hr24_5yr THEN 1
				WHEN  per24_48.one_day > per_day.hr24_5yr AND per24_48.one_day <= per_day.hr24_10yr THEN 2
				WHEN  per24_48.one_day > per_day.hr24_10yr AND per24_48.one_day <= per_day.hr24_50yr THEN 3
				WHEN  per24_48.one_day > per_day.hr24_50yr AND per24_48.one_day <= per_day.hr24_100yr THEN 4
				WHEN  per24_48.one_day > per_day.hr24_100yr THEN 5
			END AS
			risk_level_one_day,
			CASE
				WHEN  per24_48.two_day <= per_day.hr48_5yr THEN 1
				WHEN  per24_48.two_day > per_day.hr48_5yr AND per24_48.two_day <= per_day.hr48_10yr THEN 2
				WHEN  per24_48.two_day > per_day.hr48_10yr AND per24_48.two_day <= per_day.hr48_50yr THEN 3
				WHEN  per24_48.two_day > per_day.hr48_50yr AND per24_48.two_day <= per_day.hr48_100yr THEN 4
				WHEN  per24_48.two_day > per_day.hr48_100yr THEN 5
			END AS
			risk_level_two_day,
			GREATEST(
			CASE
				WHEN  per24_48.one_day <= per_day.hr24_5yr THEN 1
				WHEN  per24_48.one_day > per_day.hr24_5yr AND per24_48.one_day <= per_day.hr24_10yr THEN 2
				WHEN  per24_48.one_day > per_day.hr24_10yr AND per24_48.one_day <= per_day.hr24_50yr THEN 3
				WHEN  per24_48.one_day > per_day.hr24_50yr AND per24_48.one_day <= per_day.hr24_100yr THEN 4
				WHEN  per24_48.one_day > per_day.hr24_100yr THEN 5
				END, 
			CASE
				WHEN  per24_48.two_day <= per_day.hr48_5yr THEN 1
				WHEN  per24_48.two_day > per_day.hr48_5yr AND per24_48.two_day <= per_day.hr48_10yr THEN 2
				WHEN  per24_48.two_day > per_day.hr48_10yr AND per24_48.two_day <= per_day.hr48_50yr THEN 3
				WHEN  per24_48.two_day > per_day.hr48_50yr AND per24_48.two_day <= per_day.hr48_100yr THEN 4
				WHEN  per24_48.two_day > per_day.hr48_100yr THEN 5
			END) as risk_level
			from
				per24_48
			JOIN
				per_day 
			USING
				(sentinel_id,dt)
			WHERE 
				per24_48.sentinel_id = in_sentinel_id
			AND 
				per24_48.dt >= (SELECT data.sentinel_current_forecast_made_at(in_sentinel_id)::date)
			ORDER BY sentinel_id,dt;
	END
	$BODY$;

-- stored procedure for risk levels of sentinels for previous forecasts 
CREATE OR REPLACE FUNCTION data.get_sentinel_one_and_two_day_previous_forecast_risk_level(
	in_sentinel_id integer,
	OUT sentinel_id integer,
	OUT dt date,
	OUT one_day double precision,
	OUT two_day double precision,
	OUT risk_level_one_day integer,
	OUT risk_level_two_day integer,
	OUT risk_level integer
)
	RETURNS SETOF RECORD
	LANGUAGE 'plpgsql'

	COST 100
	VOLATILE
	ROWS 10
AS $BODY$
	BEGIN
		RETURN QUERY
with hourly_rainfall as(	
SELECT
  	 	a.sentinel_id, 
		a.forecast_made_at,
		a.forecast_1h,
		a.value
  	FROM
  		data.sentinels_forecast a
  	WHERE
  		a.forecast_made_at = (SELECT data.sentinel_previous_forecast_made_at(in_sentinel_id))
	and 
		a.model_id = 9 
), per_day as (
		SELECT
			c.sentinel_id,
			c.hr24_5yr,
			c.hr24_10yr,
			c.hr24_20yr,
			c.hr24_50yr,
			c.hr24_100yr,
			c.hr48_5yr,
			c.hr48_10yr,
			c.hr48_20yr,
			c.hr48_50yr,
			c.hr48_100yr,
			b.forecast_1h::date as dt,
			sum(b.value) as one_day
		FROM
			hourly_rainfall b
		JOIN
			data.sentinels c
		USING
			(sentinel_id)
		WHERE
			b.sentinel_id = in_sentinel_id
		GROUP BY 
			b.forecast_1h::date, 
			c.sentinel_id,
			c.hr24_5yr,
			c.hr24_10yr,
			c.hr24_20yr,
			c.hr24_50yr,
			c.hr24_100yr,
			c.hr48_5yr,
			c.hr48_10yr,
			c.hr48_20yr,
			c.hr48_50yr,
			c.hr48_100yr
			), per24_48 as (
					SELECT
						per_day.*,
						sum(per_day.one_day) over (ORDER BY per_day.dt
	   						rows between current row and 1 following) as two_day
					FROM
						per_day
			)
			SELECT
				per24_48.sentinel_id,
				per24_48.dt,
				per24_48.one_day,
				per24_48.two_day,
			CASE
				WHEN  per24_48.one_day <= per_day.hr24_5yr THEN 1
				WHEN  per24_48.one_day > per_day.hr24_5yr AND per24_48.one_day <= per_day.hr24_10yr THEN 2
				WHEN  per24_48.one_day > per_day.hr24_10yr AND per24_48.one_day <= per_day.hr24_50yr THEN 3
				WHEN  per24_48.one_day > per_day.hr24_50yr AND per24_48.one_day <= per_day.hr24_100yr THEN 4
				WHEN  per24_48.one_day > per_day.hr24_100yr THEN 5
			END AS
			risk_level_one_day,
			CASE
				WHEN  per24_48.two_day <= per_day.hr48_5yr THEN 1
				WHEN  per24_48.two_day > per_day.hr48_5yr AND per24_48.two_day <= per_day.hr48_10yr THEN 2
				WHEN  per24_48.two_day > per_day.hr48_10yr AND per24_48.two_day <= per_day.hr48_50yr THEN 3
				WHEN  per24_48.two_day > per_day.hr48_50yr AND per24_48.two_day <= per_day.hr48_100yr THEN 4
				WHEN  per24_48.two_day > per_day.hr48_100yr THEN 5
			END AS
			risk_level_two_day,
			GREATEST(
			CASE
				WHEN  per24_48.one_day <= per_day.hr24_5yr THEN 1
				WHEN  per24_48.one_day > per_day.hr24_5yr AND per24_48.one_day <= per_day.hr24_10yr THEN 2
				WHEN  per24_48.one_day > per_day.hr24_10yr AND per24_48.one_day <= per_day.hr24_50yr THEN 3
				WHEN  per24_48.one_day > per_day.hr24_50yr AND per24_48.one_day <= per_day.hr24_100yr THEN 4
				WHEN  per24_48.one_day > per_day.hr24_100yr THEN 5
				END, 
			CASE
				WHEN  per24_48.two_day <= per_day.hr48_5yr THEN 1
				WHEN  per24_48.two_day > per_day.hr48_5yr AND per24_48.two_day <= per_day.hr48_10yr THEN 2
				WHEN  per24_48.two_day > per_day.hr48_10yr AND per24_48.two_day <= per_day.hr48_50yr THEN 3
				WHEN  per24_48.two_day > per_day.hr48_50yr AND per24_48.two_day <= per_day.hr48_100yr THEN 4
				WHEN  per24_48.two_day > per_day.hr48_100yr THEN 5
			END) as risk_level
			from
				per24_48
			JOIN
				per_day 
			USING
				(sentinel_id,dt)
			WHERE 
				per24_48.sentinel_id = in_sentinel_id
			AND 
				per24_48.dt >= (SELECT data.sentinel_current_forecast_made_at(in_sentinel_id)::date)
			ORDER BY sentinel_id,dt;
	END
	$BODY$;

--stored procedure for asset's rainfall bar chart 
CREATE OR REPLACE FUNCTION data.get_asset_rainfall_bar_chart(
in_asset_id integer,
OUT bar_chart_data json
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
 			JSON_AGG(b)
 		FROM
 		(
 		with buckets_3hr as(
 				SELECT 
 					* 
 				FROM 
 					data.get_asset_3hr_buckets(in_asset_id)
 			)
 			SELECT
 				buckets_3hr.forecast_1h_local,
 				buckets_3hr.value_3h,
 				a.risk_level
 			FROM
 				buckets_3hr
			JOIN
 				(SELECT * FROM data.get_asset_one_and_two_day_forecast_risk_level(in_asset_id)) a
 			ON
 				a.dt = buckets_3hr.forecast_1h_local::date)b;
 	END
 	$BODY$;

--stored procedure for sentinel's rainfall bar chart 
CREATE OR REPLACE FUNCTION data.get_sentinel_rainfall_bar_chart(
in_sentinel_id integer,
OUT bar_chart_data json
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
 			JSON_AGG(b)
 		FROM
 		(
 		with buckets_3hr as(
 				SELECT 
 					* 
 				FROM 
 					data.get_sentinel_3hr_buckets(in_sentinel_id)
 			)
 			SELECT
 				buckets_3hr.forecast_1h_local,
 				buckets_3hr.value_3h,
 				a.risk_level
 			FROM
 				buckets_3hr
			JOIN
 				(SELECT * FROM data.get_sentinel_one_and_two_day_forecast_risk_level(in_sentinel_id)) a
 			ON
 				a.dt = buckets_3hr.forecast_1h_local::date)b;
 	END
 	$BODY$;

--stored procedure for assets rainfall table/calendar day

CREATE OR REPLACE FUNCTION data.get_asset_calendar_day_table(
in_asset_id integer,
OUT asset_calendar_day_data json
)
	RETURNS SETOF json
	LANGUAGE 'plpgsql'

	COST 100
  	VOLATILE
  	ROWS 1
 	AS $BODY$
 	BEGIN
 		RETURN QUERY
		with b as (
		SELECT
			asset_id,
			land_disturbance_fire,
			land_disturbance_road,
		CASE
			WHEN 
			(SELECT max(risk_level) from data.get_asset_one_and_two_day_previous_forecast_risk_level(in_asset_id))
			>
			(SELECT max(risk_level) from data.get_asset_one_and_two_day_current_forecast_risk_level(in_asset_id))
		THEN 'down'
		WHEN
		(SELECT max(risk_level) from data.get_asset_one_and_two_day_previous_forecast_risk_level(in_asset_id))
		<
		(SELECT max(risk_level) from data.get_asset_one_and_two_day_current_forecast_risk_level(in_asset_id))
		THEN 'up'
		WHEN 
		(SELECT max(risk_level) from data.get_asset_one_and_two_day_previous_forecast_risk_level(in_asset_id))
		=
		(SELECT max(risk_level) from data.get_asset_one_and_two_day_current_forecast_risk_level(in_asset_id))
		THEN 'no change'
		END as change_from_previous_forecast
		FROM
			data.assets
		WHERE 
		asset_id = in_asset_id
		), ts as (
		SELECT
			dt,
			one_day as daily_ppt,
			risk_level
		FROM
			data.get_asset_one_and_two_day_current_forecast_risk_level(in_asset_id)
		), ts_json as (
		SELECT
			json_agg(ts) as ts
		FROM
			ts
		), build_up as (
		SELECT
			asset_id,
			land_disturbance_fire,
			land_disturbance_road, 
			change_from_previous_forecast,
			ts
		FROM
			b
		CROSS JOIN
			ts_json
		)
		SELECT
		json_agg(build_up)
		FROM
		build_up;
	END
	$BODY$;
--stored procedure for sentinel rainfall table/calendar day

CREATE OR REPLACE FUNCTION data.get_sentinel_calendar_day_table(
in_sentinel_id integer,
OUT sentinel_calendar_day_data json
)
	RETURNS SETOF json
	LANGUAGE 'plpgsql'

	COST 100
  	VOLATILE
  	ROWS 1
 	AS $BODY$
 	BEGIN
 		RETURN QUERY
		with b as (
		SELECT
			sentinel_id,
		CASE
			WHEN 
			(SELECT max(risk_level) from data.get_sentinel_one_and_two_day_previous_forecast_risk_level(in_sentinel_id))
			>
			(SELECT max(risk_level) from data.get_sentinel_one_and_two_day_current_forecast_risk_level(in_sentinel_id))
		THEN 'down'
		WHEN
		(SELECT max(risk_level) from data.get_sentinel_one_and_two_day_previous_forecast_risk_level(in_sentinel_id))
		<
		(SELECT max(risk_level) from data.get_sentinel_one_and_two_day_current_forecast_risk_level(in_sentinel_id))
		THEN 'up'
		WHEN 
		(SELECT max(risk_level) from data.get_sentinel_one_and_two_day_previous_forecast_risk_level(in_sentinel_id))
		=
		(SELECT max(risk_level) from data.get_sentinel_one_and_two_day_current_forecast_risk_level(in_sentinel_id))
		THEN 'no change'
		END as change_from_previous_forecast
		FROM
			data.sentinels
		WHERE 
		sentinel_id = in_sentinel_id
		), ts as (
		SELECT
			dt,
			one_day as daily_ppt,
			risk_level
		FROM
			data.get_sentinel_one_and_two_day_current_forecast_risk_level(in_sentinel_id)
		), ts_json as (
		SELECT
			json_agg(ts) as ts
		FROM
			ts
		), build_up as (
		SELECT
			sentinel_id,
			change_from_previous_forecast,
			ts
		FROM
			b
		CROSS JOIN
			ts_json
		)
		SELECT
		json_agg(build_up)
		FROM
		build_up;
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

 -- stored procedure for watershed AEP values in the report 
CREATE OR REPLACE FUNCTION data.asset_watershed_aep(
in_asset_id integer,
OUT watershed_aep_data json
)
	RETURNS SETOF json
	LANGUAGE 'plpgsql'
	COST 100
  	VOLATILE
  	ROWS 1
 	AS $BODY$
 	BEGIN
 		RETURN QUERY
			SELECT row_to_json(c)
			FROM(
			SELECT
				a.asset_id,
				a.watershed_feature_id,
				b.hr24_5yr,
				b.hr24_10yr,
				b.hr24_20yr,
				b.hr24_50yr,
				b.hr24_100yr,
				b.hr48_5yr,
				b.hr48_10yr,
				b.hr48_20yr,
				b.hr48_50yr,
				b.hr48_100yr
			FROM
				data.assets a
			JOIN
				data.pf_grids_aep_rollup b
			USING 
				(watershed_feature_id)
			WHERE 
				asset_id = in_asset_id
				)c;
			END
			$BODY$;
