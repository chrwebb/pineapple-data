-- data.assets triggers: 
-- trigger function
CREATE OR REPLACE FUNCTION fn_geo_update_event() RETURNS trigger AS 
  $BODY$  
	BEGIN
	-- as this is an after trigger, NEW contains all the information we need even for INSERT
	NEW.geom4326 =  ST_SetSRID(ST_MakePoint(NEW.longitude,NEW.latitude), 4326);
	NEW.created = now() at time zone 'utc';
	RAISE NOTICE 'UPDATING geom4326 field for asset_id: %, asset_name: %, [%,%]' , NEW.asset_id, NEW.asset_name, NEW.latitude, NEW.longitude;	
    RETURN NEW; 
  END;
 $BODY$
LANGUAGE plpgsql VOLATILE
COST 100;

-- triggers
-- INSERT trigger
DROP TRIGGER IF EXISTS assets_table_inserted ON data.assets;
CREATE TRIGGER assets_table_inserted
  BEFORE INSERT ON data.assets
  FOR EACH ROW
  EXECUTE PROCEDURE fn_geo_update_event();


 --  UPDATE trigger
DROP TRIGGER IF EXISTS assets_table_geo_updated ON data.assets;
CREATE TRIGGER assets_table_geo_updated
  AFTER UPDATE OF 
  latitude,
  longitude
  ON data.assets
  FOR EACH ROW
  EXECUTE PROCEDURE fn_geo_update_event();