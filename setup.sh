psql postgres://${PGUSER}:${PGPASS}@${PGHOST}:${PGPORT}/${PGDATABASE} -v ON_ERROR_STOP=1 -f setup/initialize_schema.sql
mkdir -p data

# wget, unzip and place in data folder
# ogr2ogr to postgres

rm -f utils/db.ini
printf '[pg_connection]\nhost=${PGHOST}\ndbname=${PGDATABASE}\nuser=${PGUSER}\nport=${PGPORT}\npassword=${PGPASS}' > utils/db.ini