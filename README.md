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
	- bcdata Python Library

```sh
sudo apt install make
sudo apt install unzip
sudo apt-get install gdal-bin
sudo apt install postgresql-client-12
sudo apt install postgis
sudo apt-get install p7zip-full
```

```sh
pip install bcdata
```


2. Ensure you have `PG` environment variables set to point at your database, for example:
```sh
export PGHOST=localhost
export PGPORT=5432
export PGDATABASE=pineapple
export PGUSER=username
export PGPASSWORD=password
export PGTILESERVER_PASSWORD=password
```
			

3. Download the repo and run the setup bash file
```sh
git clone git@github.com:FoundrySpatial/flood-project.git
cd flood-project
./setup.sh
```

4. Choose a data setup bash file depending on if full data is desired or not
```sh
./setup_full_data.sh
```
```sh
./setup_seed_data.sh
```