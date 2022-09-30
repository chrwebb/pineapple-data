# Overview

This is a proof-of-concept for using azure container instances to run cron jobs for data formatting. It was created to demonstrate the following:
- Creating an azure container instance through terraform
- Authenticating to the azure container registry (ACR), storage account, and database
- Containers spinning down after workload and up on az commands (which can be added to a gh action cron)

## Contents

- `/terraform`: directory to create the container instance
- `/src`: Directory for the containerized python app

## Geting started

The container instance pulls an image from ACR, and requires credentials to do so. See [here](https://docs.microsoft.com/en-us/azure/container-registry/container-registry-auth-aci#create-a-service-principal) for information on creating a service principle to do so. The resulting credentials can be added to a `secrets.tfvars` in the `terraform` directory.

It also requires environment variables to be able to connect to the database. These should also be provided in the `secrets.tfvars` file.

Finally, the url env variable can be any url (the program simply prints the status code of the response) but has been kept as a sensitive secret incase a SAS url is used. The `secrets.tfvars` file should then have the following format:

```
acr_username=
acr_password=
url=
psql_db=
psql_host=
psql_port=
psql_user=
psql_password=
```

Then run `terraform apply -var-file="secrets.tfvars"` to instantiate the container instance.

## Running

Once created, the container group only incurs costs while a container within it is running. The container group will continue to exist, with its containers in a terminated state. The container can be rerun with the command `az container start --name <name> --resource-group <resource group>`.

To run as a cron job, a github action with a [schedule trigger](https://docs.github.com/en/actions/using-workflows/events-that-trigger-workflows#schedule) can be made using the [azure cli action](https://github.com/marketplace/actions/azure-cli-action) to run the above command on a schedule.