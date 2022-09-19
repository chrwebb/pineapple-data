ALTER FUNCTION data.fire_polygons_tiles_for_year(z integer, x integer, y integer, in_year integer) SECURITY DEFINER SET search_path = public;
ALTER FUNCTION data.watershed_polygon_tiles_for_asset(z integer, x integer, y integer, in_asset_id integer) SECURITY DEFINER SET search_path = public;
ALTER FUNCTION data.asset_point_tiles_for_group(z integer, x integer, y integer, in_group_id integer) SECURITY DEFINER SET search_path = public;
ALTER FUNCTION data.sentinel_point_tiles_for_group(z integer, x integer, y integer, in_group_id integer) SECURITY DEFINER SET search_path = public;

GRANT USAGE ON SCHEMA data TO tileserver_user;

GRANT EXECUTE ON FUNCTION data.fire_polygons_tiles_for_year TO tileserver_user;
GRANT EXECUTE ON FUNCTION data.watershed_polygon_tiles_for_asset TO tileserver_user;
GRANT EXECUTE ON FUNCTION data.asset_point_tiles_for_group TO tileserver_user;
GRANT EXECUTE ON FUNCTION data.sentinel_point_tiles_for_group TO tileserver_user;
