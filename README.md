# where-for-dinner-tshirt-size

## Description

Where For Dinner T-Shirt sizing is a set of scripts and templates for creating a stock sized configuration for the Where For Dinner application.  The scripts allows for one 
of three sizes to be created along with a few customizations such as workload and service name spaces, service names, and database type.  The output of the scripts are a set 
of configurations files for a give size and workload name space to deploy the application in along with a `install1` script to deploy the application which can executed 
either at the same time the configurations files are created or at a later time.  The output configuration files can also be archived for later use.

## Usage

### Create A Deployment Configuration

To create a deployment configuration, clone this repository to your workstation, navigate to the project directory, and run the following command:

```
./buildTShirt.sh
```

This will ask for series of configuration options including the T-Size and namespace where the application (workloads) will be installed.  The configuration files will be 
output to a new sub-directory using the naming pattern `<size>-<workload namespace>`.  This sub-directory contains everything needed to deploy the configured instance of 
the Where For Dinner application meaning this sub-directory can be archived for later use.


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
   
- **large** - This includes all of the services of the `medium` size the the following services and workloads
    - Crawler Service
    - Redis

    
A lot additional configuration options are mainly service naming.  It is recommended that service names are unique per application configuration.  Each configuration of the application is also required to be deployed into its own workload namespace, however the same service instance namespace can be shared.

There are three configuration options that are not naming related:

- **Database Type** - For medium and large sizes, the database types of Postgres or MySQL are valid options and the install script will spin up an instance of the selected database type.
- **Use Web Workload Type** - If set to yes, all workloads will use the `web` workload type.  If no, then the server and worker workload types will be applied to 
appropriate workloads.
- **Use Test/Scan Supply Chain**  - If set to yes, a testing/scanning supply chain will be used to build the workloads (assuming an appropriate supply chain has been installed).

###  Service Requirements

As stated in the Where For Dinner TAP installation [page](https://github.com/vmware-tanzu/application-accelerator-samples/blob/main/where-for-dinner/doc/TAPDeployment.md), 
Where For Dinner requires the RabbitMQ operator to be installed.  

Postres and MySQL usage assumes the Tanzu K8s deployment of both of these offerings, and the operators need to be installed on the cluster.

Redis is deployed by pulling a Bitnami image on the fly, so no pre-installation needs to be done for Redis usage.
