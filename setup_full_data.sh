#!/bin/bash

function main {
	# New data functions will need to be added to this list
	[ -z "$1" ] && { fire; road; } || $1
}

function fire {
	bcdata bc2pg fire-perimeters-historical --db_url postgres://$PGUSER:$PGPASSWORD@$PGHOST:$PGPORT/$PGDATABASE --table fire_historical --schema staging
	bcdata bc2pg fire-perimeters-current --db_url postgres://$PGUSER:$PGPASSWORD@$PGHOST:$PGPORT/$PGDATABASE --table fire_current --schema staging
	psql postgres://$PGUSER:$PGPASSWORD@$PGHOST:$PGPORT/$PGDATABASE -v ON_ERROR_STOP=1 -f setup/populate_fire_table.sql
}

function road {
	bcdata bc2pg forest-tenure-road-section-lines --db_url postgres://$PGUSER:$PGPASSWORD@$PGHOST:$PGPORT/$PGDATABASE --table forest_roads --schema staging --promote_to_multi
	bcdata bc2pg digital-road-atlas-dra-master-partially-attributed-roads --db_url postgres://$PGUSER:$PGPASSWORD@$PGHOST:$PGPORT/$PGDATABASE --table road_atlas --schema staging --promote_to_multi
	psql postgres://$PGUSER:$PGPASSWORD@$PGHOST:$PGPORT/$PGDATABASE -v ON_ERROR_STOP=1 -f setup/populate_road_table.sql
}

main "$@"