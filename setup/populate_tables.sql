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

INSERT INTO data.network (network_name,	network_name_long) VALUES
('ECCC','Environment Canada'),
('MOE-ASP','BC Ministry of Environment- Automated Snow Pillow Network'),
('BC MoTI', 'BC Ministry of Transportation and Infrastructure - Road Weather Stations'),
('NOAA - hydrometric', 'National Oceanic and Atmospheric Administration - Hydrometric Network'),
('NOAA - Snotel', 'National Oceanic and Atmospheric Administration - Snow Conditions');