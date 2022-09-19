DROP USER IF EXISTS tileserver_user;
CREATE USER tileserver_user WITH ENCRYPTED PASSWORD ':pgtileserver_password:';
GRANT EXECUTE ON FUNCTION data.fire_polygons_tiles_for_year TO tileserver_user;
GRANT EXECUTE ON FUNCTION data.watershed_polygon_tiles_for_asset TO tileserver_user;
GRANT EXECUTE ON FUNCTION data.asset_point_tiles_for_group TO tileserver_user;
GRANT EXECUTE ON FUNCTION data.sentinel_point_tiles_for_group TO tileserver_user;