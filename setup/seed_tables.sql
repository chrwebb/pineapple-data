INSERT INTO data.users (auth0_id, user_name) VALUES
('EAC742825A9C864A1FD3C43AF32DC', 'BC Ministry of Transportation and Infrastructure'), -- 1
('B46ABDABF476EFF1D81AC47D52524', 'City of Merritt'),                                  -- 2
('1B59418122BE218AA4E4D7A6E518E', 'City of Abbotsford'),                               -- 3
('F614FADE3125B3DB156EFDC8448D5', 'Trans Mountain Corporation');                        --4


INSERT INTO data.parents (parent_name, user_id, risk_level_threshold) VALUES
('Highway 5', 1, 1),          -- BC MOTI:                   1
('Infrastructures', 2, 1),    -- City of Merritt:           2
('Infrastructures', 3, 1),    -- City of Abbotsford:        3
('Pipelines Cluster 1', 4, 3); --Trans Mountain Corporation 4

INSERT INTO data.assets (
	asset_name, 
	asset_description, 
	parent_id, 
	latitude, 
	longitude, 
	watershed_feature_id, 
	aoi_geom4326,
	aoi_area_m2,
	land_disturbance_fire, -- 0 | 1 | 2 -- trigger
	land_disturbance_road, -- 0 | 1 | 2 -- trigger
	fire_past_2_years_m2,
	fire_past_5_years_m2,
	length_of_roads_m
) VALUES

('Section 2', 'Coquihalla Summit to Merritt', 1, 49.5941, -121.0995, 10644179, ST_Multi(ST_Buffer(ST_SetSRID(ST_Point(-121.0995, 49.5941), 4326), 0.001)), ST_Area(ST_Buffer(ST_SetSRID(ST_Point(-121.0995, 49.5941), 4326), 0.001)::geography), 0, 0, 1000, 2000, 300); -- BC MOTI asset