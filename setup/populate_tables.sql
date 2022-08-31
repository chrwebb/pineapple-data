INSERT INTO data.units (unit_name) VALUES 
('mm');

INSERT INTO data.aoi_types (aoi_type) VALUES 
('Upstream Watershed'),
('Spatial Buffer');

INSERT INTO data.models (model_name, unit_id, forecast_interval, method, model_name_long) VALUES 
('ecmwf', 1, '3 hours', 'sum', 'European Centre for Medium-Range Weather Forecasts'),
('ukmo', 1, '3 hours', 'sum', 'United Kingdom Met Office Model'),
('mogreps', 1, '3 hours', 'sum', 'United Kingdom Met Office Ensemble Model'),
('nwm', 1, '3 hours', 'sum', 'National Water Model'),
('rdps', 1, '3 hours', 'sum', 'Regional Deterministic Prediction System'),
('hrdps', 1, '3 hours', 'sum', 'High Resolution Deterministic Prediction System'),
('nam-12km', 1, '3 hours', 'sum', 'North American Mesoscale 12-km resolution'),
('foundry ensemble', 1, '3 hours', 'sum', 'Foundry Spatial Ensemble');

INSERT INTO data.risk_levels (risk_level, lower_bound, upper_bound, risk_label) VALUES 
(1, Null, 5.0, 'Low'),
(2, 5.0, 10.0, 'Moderate'),
(3, 10.0, 50.0, 'High'),
(4, 50.0, 100.0, 'Extreme'),
(5, 100.0, Null, 'Exceptional');

INSERT INTO data.networks (network_name, network_name_long) VALUES
('ECCC','Environment Canada'),
('MOE-ASP','BC Ministry of Environment- Automated Snow Pillow Network'),
('BC MoTI', 'BC Ministry of Transportation and Infrastructure - Road Weather Stations'),
('NOAA-hydrometric', 'National Oceanic and Atmospheric Administration - Hydrometric Network'),
('NOAA-Snotel', 'National Oceanic and Atmospheric Administration - Snow Conditions');


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