INSERT INTO data.units (unit_name) VALUES 
('mm');

INSERT INTO data.aoi_types (aoi_type) VALUES 
('Upstream Watershed'),
('Spatial Buffer');

INSERT INTO data.models (model_id, model_name, unit_id, forecast_interval, method, model_name_long) VALUES 
(1, 'ecmwf', 1, '3 hours', 'sum', 'European Centre for Medium-Range Weather Forecasts'),
(2, 'ukmo', 1, '3 hours', 'sum', 'United Kingdom Met Office Model'),
(3, 'mogreps', 1, '3 hours', 'sum', 'United Kingdom Met Office Ensemble Model'),
(4, 'nwm', 1, '3 hours', 'sum', 'National Water Model'),
(5, 'rdps', 1, '3 hours', 'sum', 'Regional Deterministic Prediction System'),
(6, 'hrdps', 1, '3 hours', 'sum', 'High Resolution Deterministic Prediction System'),
(7, 'nam-12km', 1, '3 hours', 'sum', 'North American Mesoscale 12-km resolution'),
(8, 'swe', 1, '3 hours', 'sum', 'National Water Model Snow Water Equivalent'),
(9, 'foundry-ensemble', 1, '3 hours', 'sum', 'Output of: (Average of models 1 through 7) + model 8');

INSERT INTO data.risk_levels (risk_level, lower_bound, upper_bound, risk_label) VALUES 
(1, Null, 5.0, 'Low'),
(2, 5.0, 10.0, 'Moderate'),
(3, 10.0, 50.0, 'High'),
(4, 50.0, 100.0, 'Extreme'),
(5, 100.0, Null, 'Exceptional');