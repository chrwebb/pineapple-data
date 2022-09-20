CREATE OR REPLACE FUNCTION data.fire_polygons_tiles_for_year(z integer, x integer, y integer, in_year integer)
RETURNS bytea
AS $$
DECLARE
    result bytea;
BEGIN
    WITH
    args AS (
      SELECT ST_TileEnvelope(z, x, y) AS geom
    ),
    mvtgeom AS (
      SELECT 
        ST_AsMVTGeom(t.geom3857, args.geom) AS geom,
		t.fire_year
      FROM data.fire_polygons t, args
      WHERE 
		ST_Intersects(t.geom3857, args.geom)
		AND
		t.fire_year=in_year
	)
	SELECT ST_AsMVT(mvtgeom, 'default')
	INTO result
	FROM mvtgeom;
	
	RETURN result;
END;
$$
LANGUAGE 'plpgsql'
STABLE
PARALLEL SAFE;

COMMENT ON FUNCTION data.fire_polygons_tiles_for_year IS 'Get tiled fire polygons for a year';


CREATE OR REPLACE FUNCTION data.watershed_polygon_tiles_for_asset(z integer, x integer, y integer, in_asset_id integer)
RETURNS bytea
AS $$
DECLARE
    result bytea;
BEGIN
    WITH
    args AS (
      SELECT ST_TileEnvelope(z, x, y) AS geom
    ),
    mvtgeom AS (
      SELECT 
        ST_AsMVTGeom(ST_Transform(t.aoi_geom4326, 3857), args.geom) AS geom
      FROM data.assets t, args
      WHERE 
		ST_Intersects(ST_Transform(t.aoi_geom4326, 3857), args.geom)
		AND
		t.asset_id=in_asset_id
	)
	SELECT ST_AsMVT(mvtgeom, 'default')
	INTO result
	FROM mvtgeom;
	
	RETURN result;
END;
$$
LANGUAGE 'plpgsql'
STABLE
PARALLEL SAFE;

COMMENT ON FUNCTION data.watershed_polygon_tiles_for_asset IS 'Get tiled watershed polygon for a single asset';

CREATE OR REPLACE
FUNCTION data.asset_point_tiles_for_group(z integer, x integer, y integer, in_group_id integer)
RETURNS bytea
AS $$
DECLARE
    result bytea;
BEGIN
    WITH
    args AS (
      SELECT ST_TileEnvelope(z, x, y) AS geom
    ),
    mvtgeom AS (
      SELECT 
        ST_AsMVTGeom(ST_Transform(t.geom4326, 3857), args.geom) AS geom,
		t.asset_name,
		t.asset_id,
		max(risk.risk_level) as risk
      FROM data.assets t, args
	  JOIN
		data.get_asset_one_and_two_day_current_forecast_risk_level(t.asset_id) risk
	  ON
		risk.asset_id=asset_id
      WHERE 
		ST_Intersects(ST_Transform(t.geom4326, 3857), args.geom)
		AND
		t.group_id=in_group_id
	  GROUP BY t.asset_id, args.geom
	)
	SELECT ST_AsMVT(mvtgeom, 'default')
	INTO result
	FROM mvtgeom;
	
	RETURN result;
END;
$$
LANGUAGE 'plpgsql'
STABLE
PARALLEL SAFE;

COMMENT ON FUNCTION data.asset_point_tiles_for_group IS 'Get tiled asset points for all assets in a single group';

CREATE OR REPLACE
FUNCTION data.sentinel_point_tiles_for_group(z integer, x integer, y integer, in_group_id integer)
RETURNS bytea
AS $$
DECLARE
    result bytea;
BEGIN
    WITH
    args AS (
      SELECT ST_TileEnvelope(z, x, y) AS geom
    ),
    mvtgeom AS (
      SELECT 
        ST_AsMVTGeom(ST_Transform(t.geom4326, 3857), args.geom) AS geom,
		t.sentinel_id,
		t.station_id,
		t.station_name,
		max(risk.risk_level) as risk
      FROM data.sentinels t
		JOIN
		  data.groups_sentinels relate
	    ON
		  relate.sentinel_id=t.sentinel_id
		, args
	  JOIN
		data.get_sentinel_one_and_two_day_current_forecast_risk_level(t.sentinel_id) risk
	  ON
		risk.sentinel_id=sentinel_id
	  WHERE 
		ST_Intersects(ST_Transform(t.geom4326, 3857), args.geom)
		AND
		relate.group_id=in_group_id
	  GROUP BY t.sentinel_id, args.geom
	)
	SELECT ST_AsMVT(mvtgeom, 'default')
	INTO result
	FROM mvtgeom;
	
	RETURN result;
END;
$$
LANGUAGE 'plpgsql'
STABLE
PARALLEL SAFE;

COMMENT ON FUNCTION data.sentinel_point_tiles_for_group IS 'Get tiled sentinel points for all sentinels in a single group';