# flood-project

`flood-project` is a tool.

The main functions are:

- existing

## Setup

1. Ensure the following requirements are met and the dependencies are set up
	- PostgreSQL (>=11) database with the PostGIS & PostGIS Raster extension (>=3.1) installed
		- PostGIS needed installed locally so you have access to `raster2pgsql`
	- Python 3.8
	- GDAL >= 2.2.3
	- unzip

```sh
sudo apt install make
sudo apt install unzip
sudo apt-get install gdal-bin
sudo apt install postgresql-client-12
sudo apt install postgis
sudo apt-get install p7zip-full

```


2. Ensure you have `PG` environment variables set to point at your database, for example:
```sh
export PGHOST=localhost
export PGPORT=5432
export PGDATABASE=flood
export PGUSER=username
export PGPASS=password
```
			

3. Download the repo and run the Makefile
```sh
git clone git@github.com:FoundrySpatial/flood-project.git
cd flood-project
sh setup.sh
```