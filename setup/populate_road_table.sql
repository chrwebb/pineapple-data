TRUNCATE data.road_lines;
INSERT INTO data.road_lines (geom4326) SELECT geom4326 FROM
(
	(
		SELECT 
			(ST_Dump(ST_Transform(geom,4326))).geom as geom4326 
		FROM staging.forest_roads
	) 
	UNION ALL 
	(
		SELECT 
			(ST_Dump(ST_Transform(geom,4326))).geom as geom4326 
		FROM staging.road_atlas
	)
) a;
