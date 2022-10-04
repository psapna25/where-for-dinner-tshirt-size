# hungryman-tshirt-size

## Description

Hungryman T-Shirt sizing is a set of scripts and templates for creating a stock sized configuration for the Hungryman application.  The scripts allows for one of three sizes to be created along with a few customizations such as workload and service name spaces, service names, and database type.  The output of the scripts are a set of configurations files for a give size and workload name space to deploy the application in along with a `install1` script to deploy the application which can executed either at the same time the configurations files are created or at a later time.  The output configuration files can also be archived for later use.

##Usage

### Create A Deployment Configuration

To create a deployment configuration, clone this repository to your workstation, navigate to the project directory, and run the following command:

```
./buildTShirt.sh
```

This will ask for series of configuration options including the T-Size and namespace where the application (workloads) will be installed.  The configuration files will be output to a new sub-directory using the naming pattern `<size>-<workload namespace>`.  This sub-directory contains everything needed to deploy the configured instance of the Hungryman application meaning this sub-directory can be archived for later use.


### Apply Deployment Configuration to you TAP Cluster

You will be given an option to install the application configuration at the end of the configuration generation process, or you can execute at a later time.  A file named `runInstall.sh` will be created in the new sub directory, and you can execute it by navigating the sub-directory and running the following command:

```
./runInstall.sh
```

This will execute the exact same set of commands had you instructed the configuration build script to install the configuration at the end of the configuration generation script.

**NOTE:**  The configuration install script orchestrates the order that the configuration is applied into a cluster.  An optimal install experience is observed if components like the RabbitMQ cluster and the database instance are up and running before applying later configuration like the RabbitMQ source and triggers.

### Configuration Options

The install script generates on of three stock configuration `sizes`.  

- **small** - This is the simplest configuration and consists of the following services and workloads:
    - API Gateway workload 
    - Search workload (In memory database)
    - Search Processor workload
    - Availability workload (In memory database)
    - UI workload
    - 3 Node RabbitMQ Cluster
   
- **medium** - This includes all of the services of the `small` size plus the following services and workloads
    - Notify workload
    - Persistent Database (MySQL or Postgres)
    - RabbitMQ Event Source
    - KNative eventing broker
    - KNative triggers
   
- **large** - This includes all of the services of the `medium` size the the following services and workloads
    - Crawler Service
    - Redis
    - RabbitMQ backed eventing broker
    - RabbitMQ backed triggers
    
All additional configuration options are mainly service naming with the exception of choosing between MySQL or Postgres as the database implementation.  It is recommended that service names are unique per application configuration.  Each configuration of the application is also required to be deployed into its own workload namespace, however the same service instance namespace can be shared.

###  Service Requirements

As stated in the Hungryman TAP installation [page](https://github.com/gm2552/hungryman/blob/main/doc/TAPDeployment.md), Hungryman requires the RabbitMQ operator to be installed.  It also requires the RabbitMQ topology operator to be installed if KNative eventing is used which is the case for the `medium` and `large` deployment sizes.

Postres and MySQL usage assumes the Tanzu K8s deployment of both of these offerings, and the operators need to be installed on the cluster.

Redis is deployed by pulling a Bitnami image on the fly, so no pre-installation needs to be done for Redis usage.
