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
## Azure Provisioning

See the [terraform-db](./terraform-db) directory for details.

The repository creates an azure postgresql database on a flexible server, as well as a container instance to initialize the database. The container instance requires credentials to access our azure container registry (acr) and assumes a docker image exists for it (the default variable values point to an existing image to use). To recreate the docker image, run `docker build -t <name> .` from the root of this repository. To push the new image, login to azure acr with `az acr login --name <repository-name>` and push the new image with `docker push <image-name>`.

To create the database, ensure you have the [az cli](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli) and [terraform cli](https://learn.hashicorp.com/tutorials/terraform/install-cli) installed. Then:
- Authenticate to azure with `az login`
- Create a file in the **/terraform** directory named `secrets.tfvars`, and add the following values:

``` 
acr_username=
acr_password=
psql_db=
psql_port=
psql_user=
psql_password=
```

Where `acr_username` and `acr_password` are credentials to access the azure container registry. If there is not already a service principal created,
see [here](https://learn.microsoft.com/en-us/azure/container-registry/container-registry-auth-service-principal#create-a-service-principal) for creating a new one. `psql_db` will be the name of the database, `psql_port` the port it exposes, and the user and password will be the admin credentials to access the database.

- If you haven't initialized terraform in this repository before, run `terraform init`
- Create the resources with `terraform apply -var-file="secrets.tfvars"`

This will provision an Azure Database for Postgres with network rules set to allow communication from internal azure resources . See [here](https://docs.microsoft.com/en-us/azure/azure-sql/database/firewall-configure?view=azuresql#connections-from-inside-azure) for information on the inter-service network rules.

**Known Issue**: When running `terraform destroy`, the azure extensions cause an error when being deleted. Just run the command again if it throws an error.

## Azure db operations

If you need to connect directly with psql, you will have to change the firewall rules to get access.

1. In the azure portal, navigate to the **psql server** and select `Networking` from the lefthand menu. Under the firewall rules, click the `Add current client ip address` to allow your ip to connect. 
2. From the same page, go to `Connection strings` on the left side menu and copy the psql string, updating the dbname and password.
3. Run that command in your terminal to connect
4. Once finished, go back to connection security and remove your IP address from the firewall rules.
