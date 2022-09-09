TRUNCATE data.fire_polygons;
INSERT INTO data.fire_polygons (fire_year, geom4326) SELECT fire_year, geom4326 FROM
(
	(
		SELECT 
			fire_year, 
			ST_Multi(ST_Transform(geom,4326)) as geom4326 
		FROM 
			staging.fire_historical 
		WHERE 
			fire_year>DATE_PART('year', CURRENT_DATE)-5
	) 
	UNION ALL 
	(
		SELECT 
			fire_year, 
			ST_Multi(ST_Transform(geom,4326)) as geom4326 
		FROM 
			staging.fire_current
	)
) a;