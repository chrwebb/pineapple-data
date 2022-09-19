CREATE INDEX fire_polygon_geom3857_idx ON data.fire_polygons USING GIST (geom3857);
ANALYZE data.fire_polygons;