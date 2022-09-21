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
CREATE OR REPLACE FUNCTION data.get_asset_forecast_plus_previous_24hours_forecast
(
	in_asset_id integer,
	which_forecast varchar(10) default 'current',
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
	IF which_forecast::text = 'current'::text THEN
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
		AND
			a.asset_id = assets.asset_id
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
		AND
			a.asset_id = assets.asset_id
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
		AND
			a.asset_id = assets.asset_id
		WHERE
			a.model_id = 9
		ORDER BY 
			asset_id, forecast_1h_local;
	ELSIF which_forecast::text = 'previous'::text THEN
		RETURN QUERY
		WITH constants (asset_id, current_forecast_made_at, previous_forecast_made_at) as (
		VALUES (in_asset_id, (SELECT data.asset_previous_forecast_made_at(in_asset_id)), (SELECT data.asset_previous_forecast_made_at(in_asset_id) - INTERVAL '12 hour'))
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
		AND
			a.asset_id = assets.asset_id
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
		AND
			a.asset_id = assets.asset_id
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
		AND
			a.asset_id = assets.asset_id
		WHERE
			a.model_id = 9
		ORDER BY 
			asset_id, forecast_1h_local;
		END IF;
	END
	$BODY$;

-- stored procedure for current forecast plus previous 12 hours 
CREATE OR REPLACE FUNCTION data.get_sentinel_forecast_plus_previous_24hours_forecast
(
	in_sentinel_id integer,
	which_forecast varchar(10) default 'current',
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
	IF which_forecast::text = 'current'::text THEN
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
		AND
			a.sentinel_id = sentinels.sentinel_id
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
		AND
			a.sentinel_id = sentinels.sentinel_id
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
		on
			a.forecast_made_at = constants.current_forecast_made_at
		AND
			a.sentinel_id = sentinels.sentinel_id
		WHERE
			a.model_id = 9
		ORDER BY 
			sentinel_id, forecast_1h_local;
	ELSIF which_forecast::text = 'previous'::text THEN
		RETURN QUERY
		WITH constants (sentinel_id, current_forecast_made_at, previous_forecast_made_at) as (
		VALUES (in_sentinel_id, (SELECT data.sentinel_previous_forecast_made_at(in_sentinel_id)), (SELECT data.sentinel_previous_forecast_made_at(in_sentinel_id) - INTERVAL '12 hour'))
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
		AND
			a.sentinel_id = sentinels.sentinel_id
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
		AND
			a.sentinel_id = sentinels.sentinel_id
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
		on
			a.forecast_made_at = constants.current_forecast_made_at
		AND
			a.sentinel_id = sentinels.sentinel_id
		WHERE
			a.model_id = 9
		ORDER BY 
			sentinel_id, forecast_1h_local;
		END IF;
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
		'duration', storm.storm_duration,
		'start_date', storm.storm_start_date,
		'value', storm.storm_magnitude
		) as historic_storms_data
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
				data.get_asset_forecast_plus_previous_24hours_forecast(in_asset_id) full_data
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
				data.get_sentinel_forecast_plus_previous_24hours_forecast(in_sentinel_id) full_data
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
			data.get_asset_forecast_plus_previous_24hours_forecast(in_asset_id) a
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
				WHEN per24_48.one_day <= hr24_5yr THEN 1
				WHEN per24_48.one_day > hr24_5yr AND per24_48.one_day <= hr24_10yr THEN 2
				WHEN per24_48.one_day > hr24_10yr AND per24_48.one_day <= hr24_50yr THEN 3
				WHEN per24_48.one_day > hr24_50yr AND per24_48.one_day <= hr24_100yr THEN 4
				WHEN per24_48.one_day > hr24_100yr THEN 5
			END AS
			risk_level_one_day,
			CASE
				WHEN per24_48.two_day <= hr48_5yr THEN 1
				WHEN per24_48.two_day > hr48_5yr AND per24_48.two_day <= hr48_10yr THEN 2
				WHEN per24_48.two_day > hr48_10yr AND per24_48.two_day <= hr48_50yr THEN 3
				WHEN per24_48.two_day > hr48_50yr AND per24_48.two_day <= hr48_100yr THEN 4
				WHEN per24_48.two_day > hr48_100yr THEN 5
			END AS
			risk_level_two_day,
			GREATEST(
			CASE
				WHEN per24_48.one_day <= hr24_5yr THEN 1
				WHEN per24_48.one_day > hr24_5yr AND per24_48.one_day <= hr24_10yr THEN 2
				WHEN per24_48.one_day > hr24_10yr AND per24_48.one_day <= hr24_50yr THEN 3
				WHEN per24_48.one_day > hr24_50yr AND per24_48.one_day <= hr24_100yr THEN 4
				WHEN per24_48.one_day > hr24_100yr THEN 5
				END, 
			CASE
				WHEN per24_48.two_day <= hr48_5yr THEN 1
				WHEN per24_48.two_day > hr48_5yr AND per24_48.two_day <= hr48_10yr THEN 2
				WHEN per24_48.two_day > hr48_10yr AND per24_48.two_day <= hr48_50yr THEN 3
				WHEN per24_48.two_day > hr48_50yr AND per24_48.two_day <= hr48_100yr THEN 4
				WHEN per24_48.two_day > hr48_100yr THEN 5
			END) as risk_level
			from
				per24_48
			JOIN
				data.pf_grids_aep_rollup r
			USING
				(watershed_feature_id)
			WHERE 
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
		a.forecast_1h_local,
		a.value
	FROM
		data.get_asset_forecast_plus_previous_24hours_forecast(in_asset_id, 'previous') a

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
				WHEN per24_48.one_day <= hr24_5yr THEN 1
				WHEN per24_48.one_day > hr24_5yr AND per24_48.one_day <= hr24_10yr THEN 2
				WHEN per24_48.one_day > hr24_10yr AND per24_48.one_day <= hr24_50yr THEN 3
				WHEN per24_48.one_day > hr24_50yr AND per24_48.one_day <= hr24_100yr THEN 4
				WHEN per24_48.one_day > hr24_100yr THEN 5
			END AS
			risk_level_one_day,
			CASE
				WHEN per24_48.two_day <= hr48_5yr THEN 1
				WHEN per24_48.two_day > hr48_5yr AND per24_48.two_day <= hr48_10yr THEN 2
				WHEN per24_48.two_day > hr48_10yr AND per24_48.two_day <= hr48_50yr THEN 3
				WHEN per24_48.two_day > hr48_50yr AND per24_48.two_day <= hr48_100yr THEN 4
				WHEN per24_48.two_day > hr48_100yr THEN 5
			END AS
			risk_level_two_day,
			GREATEST(
			CASE
				WHEN per24_48.one_day <= hr24_5yr THEN 1
				WHEN per24_48.one_day > hr24_5yr AND per24_48.one_day <= hr24_10yr THEN 2
				WHEN per24_48.one_day > hr24_10yr AND per24_48.one_day <= hr24_50yr THEN 3
				WHEN per24_48.one_day > hr24_50yr AND per24_48.one_day <= hr24_100yr THEN 4
				WHEN per24_48.one_day > hr24_100yr THEN 5
				END, 
			CASE
				WHEN per24_48.two_day <= hr48_5yr THEN 1
				WHEN per24_48.two_day > hr48_5yr AND per24_48.two_day <= hr48_10yr THEN 2
				WHEN per24_48.two_day > hr48_10yr AND per24_48.two_day <= hr48_50yr THEN 3
				WHEN per24_48.two_day > hr48_50yr AND per24_48.two_day <= hr48_100yr THEN 4
				WHEN per24_48.two_day > hr48_100yr THEN 5
			END) as risk_level
			from
				per24_48
			JOIN
				data.pf_grids_aep_rollup r
			USING
				(watershed_feature_id)
			WHERE 
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
		data.get_sentinel_forecast_plus_previous_24hours_forecast(in_sentinel_id) a
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
				WHEN per24_48.one_day <= per_day.hr24_5yr THEN 1
				WHEN per24_48.one_day > per_day.hr24_5yr AND per24_48.one_day <= per_day.hr24_10yr THEN 2
				WHEN per24_48.one_day > per_day.hr24_10yr AND per24_48.one_day <= per_day.hr24_50yr THEN 3
				WHEN per24_48.one_day > per_day.hr24_50yr AND per24_48.one_day <= per_day.hr24_100yr THEN 4
				WHEN per24_48.one_day > per_day.hr24_100yr THEN 5
			END AS
			risk_level_one_day,
			CASE
				WHEN per24_48.two_day <= per_day.hr48_5yr THEN 1
				WHEN per24_48.two_day > per_day.hr48_5yr AND per24_48.two_day <= per_day.hr48_10yr THEN 2
				WHEN per24_48.two_day > per_day.hr48_10yr AND per24_48.two_day <= per_day.hr48_50yr THEN 3
				WHEN per24_48.two_day > per_day.hr48_50yr AND per24_48.two_day <= per_day.hr48_100yr THEN 4
				WHEN per24_48.two_day > per_day.hr48_100yr THEN 5
			END AS
			risk_level_two_day,
			GREATEST(
			CASE
				WHEN per24_48.one_day <= per_day.hr24_5yr THEN 1
				WHEN per24_48.one_day > per_day.hr24_5yr AND per24_48.one_day <= per_day.hr24_10yr THEN 2
				WHEN per24_48.one_day > per_day.hr24_10yr AND per24_48.one_day <= per_day.hr24_50yr THEN 3
				WHEN per24_48.one_day > per_day.hr24_50yr AND per24_48.one_day <= per_day.hr24_100yr THEN 4
				WHEN per24_48.one_day > per_day.hr24_100yr THEN 5
				END, 
			CASE
				WHEN per24_48.two_day <= per_day.hr48_5yr THEN 1
				WHEN per24_48.two_day > per_day.hr48_5yr AND per24_48.two_day <= per_day.hr48_10yr THEN 2
				WHEN per24_48.two_day > per_day.hr48_10yr AND per24_48.two_day <= per_day.hr48_50yr THEN 3
				WHEN per24_48.two_day > per_day.hr48_50yr AND per24_48.two_day <= per_day.hr48_100yr THEN 4
				WHEN per24_48.two_day > per_day.hr48_100yr THEN 5
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
		a.forecast_1h_local,
		a.value
	FROM
		data.get_sentinel_forecast_plus_previous_24hours_forecast(in_sentinel_id, 'previous') a
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
				WHEN per24_48.one_day <= per_day.hr24_5yr THEN 1
				WHEN per24_48.one_day > per_day.hr24_5yr AND per24_48.one_day <= per_day.hr24_10yr THEN 2
				WHEN per24_48.one_day > per_day.hr24_10yr AND per24_48.one_day <= per_day.hr24_50yr THEN 3
				WHEN per24_48.one_day > per_day.hr24_50yr AND per24_48.one_day <= per_day.hr24_100yr THEN 4
				WHEN per24_48.one_day > per_day.hr24_100yr THEN 5
			END AS
			risk_level_one_day,
			CASE
				WHEN per24_48.two_day <= per_day.hr48_5yr THEN 1
				WHEN per24_48.two_day > per_day.hr48_5yr AND per24_48.two_day <= per_day.hr48_10yr THEN 2
				WHEN per24_48.two_day > per_day.hr48_10yr AND per24_48.two_day <= per_day.hr48_50yr THEN 3
				WHEN per24_48.two_day > per_day.hr48_50yr AND per24_48.two_day <= per_day.hr48_100yr THEN 4
				WHEN per24_48.two_day > per_day.hr48_100yr THEN 5
			END AS
			risk_level_two_day,
			GREATEST(
			CASE
				WHEN per24_48.one_day <= per_day.hr24_5yr THEN 1
				WHEN per24_48.one_day > per_day.hr24_5yr AND per24_48.one_day <= per_day.hr24_10yr THEN 2
				WHEN per24_48.one_day > per_day.hr24_10yr AND per24_48.one_day <= per_day.hr24_50yr THEN 3
				WHEN per24_48.one_day > per_day.hr24_50yr AND per24_48.one_day <= per_day.hr24_100yr THEN 4
				WHEN per24_48.one_day > per_day.hr24_100yr THEN 5
				END, 
			CASE
				WHEN per24_48.two_day <= per_day.hr48_5yr THEN 1
				WHEN per24_48.two_day > per_day.hr48_5yr AND per24_48.two_day <= per_day.hr48_10yr THEN 2
				WHEN per24_48.two_day > per_day.hr48_10yr AND per24_48.two_day <= per_day.hr48_50yr THEN 3
				WHEN per24_48.two_day > per_day.hr48_50yr AND per24_48.two_day <= per_day.hr48_100yr THEN 4
				WHEN per24_48.two_day > per_day.hr48_100yr THEN 5
			END) as risk_level
			from
				per24_48
			JOIN
				per_day 
			USING
				(sentinel_id,dt)
			WHERE 
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
				(SELECT * FROM data.get_asset_one_and_two_day_current_forecast_risk_level(in_asset_id)) a
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
				(SELECT * FROM data.get_sentinel_one_and_two_day_current_forecast_risk_level(in_sentinel_id)) a
			ON
				a.dt = buckets_3hr.forecast_1h_local::date)b;
	END
	$BODY$;

--stored procedure for assets rainfall table/calendar day
CREATE OR REPLACE FUNCTION data.get_asset_calendar_day_table(
in_asset_id integer,
OUT	change_from_previous_forecast integer,
OUT	daily_forecast json
)
	RETURNS SETOF RECORD
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
		CASE
			WHEN 
			(SELECT max(risk_level) from data.get_asset_one_and_two_day_previous_forecast_risk_level(in_asset_id))
			>
			(SELECT max(risk_level) from data.get_asset_one_and_two_day_current_forecast_risk_level(in_asset_id))
		THEN -1
		WHEN
		(SELECT max(risk_level) from data.get_asset_one_and_two_day_previous_forecast_risk_level(in_asset_id))
		<
		(SELECT max(risk_level) from data.get_asset_one_and_two_day_current_forecast_risk_level(in_asset_id))
		THEN 1
		WHEN 
		(SELECT max(risk_level) from data.get_asset_one_and_two_day_previous_forecast_risk_level(in_asset_id))
		=
		(SELECT max(risk_level) from data.get_asset_one_and_two_day_current_forecast_risk_level(in_asset_id))
		THEN 0
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
			json_agg(ts) as daily_forecast
		FROM
			ts
		)
		SELECT
			b.change_from_previous_forecast,
			ts_json.daily_forecast
		FROM
			b
		CROSS JOIN
			ts_json;
	END
	$BODY$;
--stored procedure for sentinel rainfall table/calendar day

CREATE OR REPLACE FUNCTION data.get_sentinel_calendar_day_table(
in_sentinel_id integer,
OUT	change_from_previous_forecast integer,
OUT	daily_forecast json
)
	RETURNS SETOF RECORD
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
		THEN -1
		WHEN
		(SELECT max(risk_level) from data.get_sentinel_one_and_two_day_previous_forecast_risk_level(in_sentinel_id))
		<
		(SELECT max(risk_level) from data.get_sentinel_one_and_two_day_current_forecast_risk_level(in_sentinel_id))
		THEN 1
		WHEN 
		(SELECT max(risk_level) from data.get_sentinel_one_and_two_day_previous_forecast_risk_level(in_sentinel_id))
		=
		(SELECT max(risk_level) from data.get_sentinel_one_and_two_day_current_forecast_risk_level(in_sentinel_id))
		THEN 0
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
			json_agg(ts) as daily_forecast
		FROM
			ts
		)
		SELECT
			b.change_from_previous_forecast,
			ts_json.daily_forecast
		FROM
			b
		CROSS JOIN
			ts_json;
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


CREATE OR REPLACE FUNCTION data.asset_return_periods(
in_asset_id integer,
OUT asset_return_periods json
)
	RETURNS SETOF json
	LANGUAGE 'plpgsql'
	COST 100
		VOLATILE
		ROWS 1
	AS $BODY$
	BEGIN
		RETURN QUERY
	SELECT json_agg(c)
	FROM(
	WITH aep_values as(
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
		)
	SELECT
	r.risk_level,
	CASE 
		WHEN r.risk_level = 1 then NULL
		WHEN r.risk_level = 2 then hr24_5yr
		WHEN r.risk_level = 3 then hr24_10yr
		WHEN r.risk_level = 4 then hr24_50yr
		WHEN r.risk_level = 5 then hr24_100yr
	END AS lb24,
	CASE 
		WHEN r.risk_level = 1 then hr24_5yr
		WHEN r.risk_level = 2 then hr24_10yr
		WHEN r.risk_level = 3 then hr24_50yr
		WHEN r.risk_level = 4 then hr24_100yr
		WHEN r.risk_level = 5 then NULL
	END AS ub24,
	CASE 
		WHEN r.risk_level = 1 then NULL
		WHEN r.risk_level = 2 then hr48_5yr
		WHEN r.risk_level = 3 then hr48_10yr
		WHEN r.risk_level = 4 then hr48_50yr
		WHEN r.risk_level = 5 then hr48_100yr
	END AS lb48,
	CASE 
		WHEN r.risk_level = 1 then hr48_5yr
		WHEN r.risk_level = 2 then hr48_10yr
		WHEN r.risk_level = 3 then hr48_50yr
		WHEN r.risk_level = 4 then hr48_100yr
		WHEN r.risk_level = 5 then NULL
	END AS ub48
	FROM
		aep_values a
		cross join
		data.risk_levels r) as c;
				END
				$BODY$;

--stored procedure for get_asset_by_asset_id()

CREATE OR REPLACE FUNCTION data.get_asset_by_asset_id(
in_user_id integer,
in_asset_id integer,
OUT asset_data json
)
	RETURNS SETOF json
	LANGUAGE 'plpgsql'
	COST 100
		VOLATILE
		ROWS 1
	AS $BODY$
	BEGIN
		RETURN QUERY
	WITH buckets as(
		SELECT
			*
		FROM 
			data.get_asset_rainfall_bar_chart(in_asset_id)
	),	return_periods as(
		SELECT
			*
		FROM
			data.asset_return_periods(in_asset_id)
	),	risk as (
		SELECT 
			asset_id,
			max(risk_level) as risk_level 
		FROM 
			data.get_asset_one_and_two_day_current_forecast_risk_level(in_asset_id) 
		group by 
			asset_id
	),	antecedent as(
		SELECT
			*
		FROM
			data.get_asset_antecedent_rain(in_asset_id)
	),
		daily_forecast as(
		SELECT
			*
		FROM
			data.get_asset_calendar_day_table(in_asset_id)
	)
	SELECT 
		json_build_object(
			'id', asset.asset_id,
			'description', asset.asset_description,
			'name', asset.asset_name,
			'riskLevel', risk.risk_level,
			--'elevationsMasl', jason_build_object(asset.min_elev, asset.max_elev, asset.mean_elev),
			'location', st_AsGeojson(asset.geom4326),
			'watershedAreaKm2',asset.aoi_area_m2,
			'landDisturbance',json_build_object('fire',asset.land_disturbance_fire,'road',asset.land_disturbance_road),
			'returnPeriods', return_periods.asset_return_periods,
			'antecedentRain', antecedent.antecedant_data,
			'forecastDaily', daily_forecast.daily_forecast,
			'forecast3hour',buckets.bar_chart_data,
			'changeFromPreviousForecast', daily_forecast.change_from_previous_forecast
			)
	FROM
		data.assets asset
	JOIN
		risk
	USING
		(asset_id)
	JOIN
		data.groups
	USING
		(group_id)
	JOIN
		(SELECT * FROM data.users where user_id = in_user_id) u
	USING
		(user_id)
	CROSS JOIN 
		buckets
	CROSS JOIN
		return_periods
	CROSS JOIN
		antecedent
	CROSS JOIN
		daily_forecast;
	END
	$BODY$;


-- stored procedure for gettting sentinels by sentinel id 

CREATE OR REPLACE FUNCTION data.get_sentinel_by_sentinel_id(
in_user_id integer,
in_sentinel_id integer,
OUT sentinel_data json
)
	RETURNS SETOF json
	LANGUAGE 'plpgsql'
	COST 100
		VOLATILE
		ROWS 1
	AS $BODY$
	BEGIN
		RETURN QUERY
	WITH buckets as(
		SELECT
			*
		FROM 
			data.get_sentinel_rainfall_bar_chart(in_sentinel_id)
	),	return_periods as(
		SELECT json_agg(b) as sentinel_return_periods
		FROM(
		SELECT
			r.risk_level,
		CASE 
			WHEN r.risk_level = 1 then NULL
			WHEN r.risk_level = 2 then hr24_5yr
			WHEN r.risk_level = 3 then hr24_10yr
			WHEN r.risk_level = 4 then hr24_50yr
			WHEN r.risk_level = 5 then hr24_100yr
		END AS lb24,
		CASE 
			WHEN r.risk_level = 1 then hr24_5yr
			WHEN r.risk_level = 2 then hr24_10yr
			WHEN r.risk_level = 3 then hr24_50yr
			WHEN r.risk_level = 4 then hr24_100yr
			WHEN r.risk_level = 5 then NULL
		END AS ub24,
		CASE 
			WHEN r.risk_level = 1 then NULL
			WHEN r.risk_level = 2 then hr48_5yr
			WHEN r.risk_level = 3 then hr48_10yr
			WHEN r.risk_level = 4 then hr48_50yr
			WHEN r.risk_level = 5 then hr48_100yr
		END AS lb48,
		CASE 
			WHEN r.risk_level = 1 then hr48_5yr
			WHEN r.risk_level = 2 then hr48_10yr
			WHEN r.risk_level = 3 then hr48_50yr
			WHEN r.risk_level = 4 then hr48_100yr
			WHEN r.risk_level = 5 then NULL
		END AS ub48
		FROM
			data.sentinels a
			cross join
			data.risk_levels r
		WHERE
			a.sentinel_id = in_sentinel_id) b
	),	risk as (
		SELECT 
			sentinel_id,
			max(risk_level) as risk_level 
		FROM 
			data.get_sentinel_one_and_two_day_current_forecast_risk_level(in_sentinel_id) 
		group by 
			sentinel_id
	),	daily_forecast as(
		SELECT
			*
		FROM
			data.get_sentinel_calendar_day_table(in_sentinel_id)
	), historical_storms as(
		SELECT
			json_agg(sentinel_storms_of_record) as sentinel_storms_of_record
		FROM
			data.get_sentinel_storms_of_record(in_sentinel_id)
	), one_day_forecast_storm as(
		SELECT 
			dt,
			one_day,
			risk_level_one_day
		FROM 
			data.get_sentinel_one_and_two_day_current_forecast_risk_level(in_sentinel_id)
		ORDER BY 
			one_day DESC
		LIMIT 1
	), two_day_forecast_storm as(
		SELECT
			dt,
			two_day,
			risk_level_two_day
		FROM
			data.get_sentinel_one_and_two_day_current_forecast_risk_level(in_sentinel_id)
		ORDER BY
			two_day DESC
		LIMIT 1
	)
	SELECT 
		json_build_object(
			'id', sentinel.sentinel_id,
			'name', sentinel.station_name,
			'riskLevel', risk.risk_level,
			'elevationsMasl', sentinel.elevation_m,
			'nativeId',sentinel.station_id,
			'networkName', network.network_name,
			'location', st_AsGeojson(sentinel.geom4326),
			'forecastDaily', daily_forecast.daily_forecast,
			'forecast3hour', buckets.bar_chart_data,
			'yearsOfRecord', json_build_object('start',sentinel.start_year,'end',sentinel.end_year),
			'returnPeriods', return_periods.sentinel_return_periods,
			'forecastStorms', json_build_object('one_day',json_build_object('date',one_day_forecast_storm.dt,'duration', 1, 'value',one_day_forecast_storm.one_day,'risk_level',one_day_forecast_storm.risk_level_one_day),
											   'two_day',json_build_object('date',two_day_forecast_storm.dt,'duration', 2, 'value',two_day_forecast_storm.two_day, 'risk_level',two_day_forecast_storm.risk_level_two_day)),
			'historicalStorms',historical_storms.sentinel_storms_of_record,
			'changeFromPreviousForecast', daily_forecast.change_from_previous_forecast
			)
	FROM
		data.sentinels sentinel
	JOIN
		risk
	USING
		(sentinel_id)
	JOIN
		data.groups_sentinels groups_sentinels
	USING
		(sentinel_id)
	JOIN
		(SELECT * FROM data.users where user_id = in_user_id) u
	using
		(user_id)
	CROSS JOIN 
		buckets
	CROSS JOIN
		return_periods
	CROSS JOIN
		historical_storms
	CROSS JOIN
		daily_forecast
	CROSS JOIN
		one_day_forecast_storm
	CROSS JOIN
		two_day_forecast_storm
	JOIN
		data.networks network
	USING 
		(network_id);
	END
	$BODY$;
