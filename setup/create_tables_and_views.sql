DROP TABLE IF EXISTS data.units CASCADE;
CREATE TABLE data.units (
	unit_id int GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
	unit_name varchar(50) NOT NULL
);

DROP TABLE IF EXISTS data.aoi_types CASCADE;
CREATE TABLE data.aoi_types (
	aoi_type_id integer GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
	aoi_type text NOT NULL 
);

DROP TABLE IF EXISTS data.models CASCADE;
CREATE TABLE data.models (
	model_id smallint PRIMARY KEY, -- hard coding model id so we use with trust in queries that reference it
	model_name varchar(20) NOT NULL,
	unit_id integer  NOT NULL references data.units,
	forecast_interval interval  NOT NULL,
	method text  NOT NULL,
	model_name_long text  NOT NULL --Add more metadata fields later and populate
);


DROP TABLE IF EXISTS data.risk_levels CASCADE;
CREATE TABLE data.risk_levels (
	risk_level INTEGER NOT NULL,
	lower_bound double precision,
	upper_bound double precision,
	risk_label text  NOT NULL
);

DROP TABLE IF EXISTS data.networks CASCADE;
CREATE TABLE data.networks
(
	network_id int GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
	network_name varchar(20),
	network_name_long varchar(200)
);


DROP TABLE IF EXISTS data.climate_normals_1991_2020;
CREATE TABLE data.climate_normals_1991_2020 (
	watershed_feature_id integer  NOT NULL,
	month smallint  NOT NULL,
	unit_id integer  NOT NULL references data.units ,
	value double precision  NOT NULL,
	CONSTRAINT climate_normals_1991_2020_unique UNIQUE (watershed_feature_id, month)
);


DROP TABLE IF EXISTS data.pf_grids_aep_rollup CASCADE;
CREATE TABLE data.pf_grids_aep_rollup
(
	watershed_feature_id int PRIMARY KEY,
	hr24_5yr real NOT NULL, --Sina needs to populate this
	hr24_10yr real NOT NULL,
	hr24_20yr real NOT NULL,
	hr24_50yr real NOT NULL,
	hr24_100yr real NOT NULL,
	hr24_200yr real NOT NULL,
	hr24_500yr real NOT NULL,
	hr48_5yr real NOT NULL, --Sina needs to populate this
	hr48_10yr real NOT NULL,
	hr48_20yr real NOT NULL,
	hr48_50yr real NOT NULL,
	hr48_100yr real NOT NULL,
	hr48_200yr real NOT NULL,
	hr48_500yr real NOT NULL
);

DROP TABLE IF EXISTS data.users CASCADE;
CREATE TABLE data.users
(
	user_id int GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
	auth0_id text not null,
	user_name text not null, 
	created timestamp with time zone NOT NULL default now()
);


DROP TABLE IF EXISTS data.parents CASCADE;
CREATE TABLE data.parents
(
	parent_id int GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
	parent_name varchar(200),
	user_id integer references data.users,
	risk_level_threshold smallint default 1, --what risk level the client is notified
	created timestamp with time zone NOT NULL default now()
);

DROP TABLE IF EXISTS data.sentinels;
CREATE TABLE data.sentinels
(
	sentinel_id int GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
	station_id VARCHAR(20) UNIQUE,
	station_name VARCHAR(50),
	latitude double precision,
	longitude double precision,
	elevation_m double precision,
	geom4326 geometry(Point, 4326),
	hr24_5yr real NOT NULL, --Sina needs to populate this
	hr24_10yr real NOT NULL,
	hr24_20yr real NOT NULL,
	hr24_50yr real NOT NULL,
	hr24_100yr real NOT NULL,
	hr48_5yr real NOT NULL, --Sina needs to populate this
	hr48_10yr real NOT NULL,
	hr48_20yr real NOT NULL,
	hr48_50yr real NOT NULL,
	hr48_100yr real NOT NULL,
	network_id integer references data.networks, -- TBD: Relate to a network table
	start_year smallint, -- Relates to precip
	end_year smallint -- Relates to precip
);


DROP TABLE IF EXISTS data.sentinels_historic_storms;
CREATE TABLE data.sentinels_historic_storms
(
	sentinel_id INTEGER NOT NULL references data.sentinels,
	storm_start_date date not null,
	storm_magnitude double precision not null,
	storm_duration smallint not null, -- 1-day or 2-day storm
	unit_id INTEGER REFERENCES data.units,
	CONSTRAINT sentinels_historic_storms_unique UNIQUE (sentinel_id, storm_start_date, storm_duration)
);

DROP TABLE IF EXISTS data.parents_sentinels;
CREATE TABLE data.parents_sentinels -- One to many between parent and sentinels
(
	parent_id int NOT NULL references data.parents,
	sentinel_id int NOT NULL references data.sentinels,
	created timestamp with time zone NOT NULL default now(),
	CONSTRAINT parents_sentinels_unique UNIQUE (parent_id, sentinel_id)
);


DROP TABLE IF EXISTS data.assets;
CREATE TABLE data.assets
(
	asset_id int GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
	asset_name VARCHAR(50) NOT NULL, -- eg Culvert 1
	asset_description varchar(300) NOT NULL,
	parent_id integer  NOT NULL references data.parents,
	latitude double precision NOT NULL,
	longitude double precision NOT NULL,
	geom4326 geometry(Point, 4326) NOT NULL, -- Geometry trigger to change lat and long
	watershed_feature_id bigint  NOT NULL,
	aoi_geom4326 geometry(MultiPolygon, 4326) NOT NULL,
	aoi_area_m2 double precision NOT NULL,
	aoi_type_id int  NOT NULL DEFAULT 1 references data.aoi_types,
	land_disturbance_fire smallint NOT NULL , --must be 0, 1 or 2; triggers from fire_past_2_years_m2 or fire_past_5_years_m2
	land_disturbance_road smallint NOT NULL , --must be 0, 1 or 2; triggers from length_of_roads_m
	fire_past_2_years_m2 double precision NOT NULL , --contributes to land_disturbance_road when combined with aoi_area_m2
	fire_past_5_years_m2 double precision NOT NULL , --contributes to land_disturbance_fire when combined with aoi_area_m2
	length_of_roads_m double precision NOT NULL,  --contributes to land_disturbance_road when combined with aoi_area_m2
	created timestamp with time zone NOT NULL default now()
);


-- At the moment we're storing data in forecast_hour as a 3-hour period, This may change in the future to hourly
DROP TABLE IF EXISTS data.sentinels_forecast;
CREATE TABLE data.sentinels_forecast
(
	sentinel_id INTEGER NOT NULL references data.sentinels,
	forecast_made_at timestamp with time zone NOT NULL, --When the forecast model was ran, UTC, every 12 hours
	forecast_3h timestamp with time zone NOT NULL, --What future datetime the forecast applies to, UTC, every 3 hours summed
	model_id int NOT NULL references data.models,
	value double precision NOT NULL,
	CONSTRAINT sentinels_forecast_unique UNIQUE(sentinel_id, forecast_made_at, forecast_3h, model_id)
);

DROP TABLE IF EXISTS data.assets_forecast;
CREATE TABLE data.assets_forecast
(
	asset_id INTEGER NOT NULL references data.assets,
	forecast_made_at timestamp with time zone NOT NULL, --When the forecast model was ran, UTC, every 12 hours
	forecast_3h timestamp with time zone NOT NULL, --What future datetime the forecast applies to, UTC, every 3 hours summed
	model_id int NOT NULL references data.models,
	value double precision NOT NULL,
	CONSTRAINT assets_forecast_unique UNIQUE(asset_id, forecast_made_at, forecast_3h, model_id)
);

DROP TABLE IF EXISTS data.assets_antecedant;
CREATE TABLE data.assets_antecedant
(
	asset_id INTEGER NOT NULL references data.assets,
	seven_day double precision NOT NULL,
	thirty_day double precision NOT NULL,
	unit_id int NOT NULL references data.units,
	seven_day_pct_normal double precision NOT NULL,
	thirty_day_pct_normal double precision NOT NULL, 
	imported_at timestamp with time zone NOT NULL,
	created timestamp with time zone NOT NULL default now(),
	CONSTRAINT assets_antecedant_unique UNIQUE(asset_id, unit_id)
);

DROP TABLE IF EXISTS data.fire_polygons;
CREATE TABLE data.fire_polygons
(
	fire_id int GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
	fire_year SMALLINT NOT NULL,
	geom4326 GEOMETRY(MultiPolygon, 4326)
);

DROP TABLE IF EXISTS data.road_lines;
CREATE TABLE data.road_lines
(
	road_id int GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
	geom4326 GEOMETRY(LineString, 4326)
);