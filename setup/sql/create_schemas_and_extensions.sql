CREATE EXTENSION IF NOT EXISTS postgis;
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS postgis_raster;
SELECT postgis_extensions_upgrade();

DROP SCHEMA IF EXISTS data CASCADE;
DROP SCHEMA IF EXISTS staging CASCADE;
CREATE SCHEMA data;
CREATE SCHEMA staging;