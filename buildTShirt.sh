#!/bin/bash

default_tshirt_size=small
default_workload_namespace=workloads
default_service_namespace=service-instances
default_rabbit_name=rmq-hungryman
default_db_type=mysql
default_db_name=hungryman
default_redis_name=redis-hungryman
accept=no

# Get user input

while [ "$accept" != "yes" ]
do

#
# T-Shirt Size
#
    validSize=no
    while [ "$validSize" != "yes" ]
    do

	   printf '\nT-Shirt Size: small, medium, or large  (default %s): ' "'$default_tshirt_size'"
	
	   read tshirtSize
	
	   if [ -z "$tshirtSize" ]
	   then
	      tshirtSize=$default_tshirt_size
	   fi 

       if [ "$tshirtSize" == "small"  ] || [ "$tshirtSize" == "medium"  ] || [ "$tshirtSize" == "large"  ]
       then
          validSize=yes
       else
	      printf '\nInvalid T-Shirt size.'
          echo ' '
       fi

    done


#
# Workload namespace
#
	printf 'Workload Namespace: (default %s): ' "'$default_workload_namespace'"
	
	read workloadNamespace
	
	if [ -z "$workloadNamespace" ]
	then
	   workloadNamespace=$default_workload_namespace
	fi
	
#
# Service instace namespace
#

	printf 'Service Instance Namespace (default %s): ' "'$default_service_namespace'"
	
	read serviceNamespace
	
	if [ -z "$serviceNamespace" ]
	then
	   serviceNamespace=$default_service_namespace
	fi
	
#
# RMQ cluster name
#

    printf 'RabbitMQ Cluster Name (default %s): ' "'$default_rabbit_name'"
    
    read rabbitMQName
    
    if [ -z "$rabbitMQName" ];
    then
       rabbitMQName=$default_rabbit_name
    fi
    
#
# Database type; only use database type and instance name if T-Shirt size is medium or large
#
    if [ "$tshirtSize" == "medium" ] || [ "$tshirtSize" == "large" ]
    then
       validDBType=no
       while [ "$validDBType" != "yes" ]
       do

          printf 'Database Type: mysql or postgres: (default %s): ' "'$default_db_type'"
    
          read dbType
    
          if [ -z "$dbType" ]
          then
             dbType=$default_db_type
          fi

          if [ "$dbType" == "mysql"  ] || [ "$dbType" == "postgres"  ] 
          then
             validDBType=yes
          else
             printf '\nInvalid database type.\n'
             echo ' '
          fi
       done

#
# Database instance name 
#
       defaultDBFullName=$dbType'-'$default_db_name

       printf 'MySQL Instance Name (default %s): ' "'$defaultDBFullName'"
    
       read dbName
    
       if [ -z "$dbName" ]
       then
          dbName=$defaultDBFullName
       fi
    fi

#
# Redis instance name; only use redis instance name if the tshirtSize is large
#
    if [ "$tshirtSize" == "large" ] 
    then
       printf 'Redis Instance Name (default %s): ' "'$default_redis_name'" 
        
       read redisName
    
       if [ -z "$redisName" ]
       then
          redisName=$default_redis_name
       fi
    fi
	
	echo ' '
	echo Configured Options:
    printf '   T-Shirt size: %s\n' "[$tshirtSize]"
	printf '   Workload Namespace: %s\n' "[$workloadNamespace]"
	printf '   Service Instance Namespace: %s\n' "[$serviceNamespace]"
	printf '   RabbitMQ Cluster Name: %s\n' "[$rabbitMQName]"
    if [ "$tshirtSize" == "medium" ] || [ "$tshirtSize" == "large" ]
    then
 	   printf '   Database Type : %s\n' "[$dbType]"   
	   printf '   Database Instance Name: %s\n' "[$dbName]"
	fi
    if [ "$tshirtSize" == "large" ] 
    then
       printf '   Redis Instance Name: %s\n' "[$redisName]"
    fi
	
	echo ' '
	printf 'Accept these values: yes/no (default %s)? ' "yes"
	
	read accept
	
	if [ -z "$accept" ]
	then
	   accept=yes
	fi
done

# Apply user inputs to templates

outputDir=$tshirtSize'_'$workloadNamespace

mkdir $outputDir

printf '\nGenerating configuration files into directory %s\n' "'$outputDir'"

ytt -f ./tshirt-templates/common/rmqCluster.yaml -v rabbitMQName=$rabbitMQName -v serviceNamespace=$serviceNamespace >> ./$outputDir/rmqCluster.yaml
ytt -f ./tshirt-templates/common/rmqResourceClaim.yaml -v rabbitMQName=$rabbitMQName -v serviceNamespace=$serviceNamespace -v workloadNamespace=$workloadNamespace >> ./$outputDir/rmqResourceClaim.yaml
ytt -f ./tshirt-templates/$tshirtSize/workloads.yaml -v rabbitMQName=$rabbitMQName -v serviceNamespace=$serviceNamespace -v workloadNamespace=$workloadNamespace -v dbType=$dbType -v dbName=$dbName -v redisName=$redisName  >> ./$outputDir/workloads.yaml

if [ "$tshirtSize" == "medium" ] || [ "$tshirtSize" == "large" ]
then
  dbInstanceFile=$dbType'Instance.yaml'
  dbClaimFile=$dbType'ResourceClaim.yaml'

  ytt -f ./tshirt-templates/$tshirtSize/knEventing.yaml -v rabbitMQName=$rabbitMQName -v serviceNamespace=$serviceNamespace -v workloadNamespace=$workloadNamespace >> ./$outputDir/knEventing.yaml
  ytt -f ./tshirt-templates/medium/$dbInstanceFile -v dbName=$dbName -v serviceNamespace=$serviceNamespace >> ./$outputDir/$dbInstanceFile
  ytt -f ./tshirt-templates/medium/$dbClaimFile -v dbName=$dbName -v serviceNamespace=$serviceNamespace -v workloadNamespace=$workloadNamespace >> ./$outputDir/$dbClaimFile

fi

if [ "$tshirtSize" == "medium" ] || [ "$tshirtSize" == "large" ]
then
  ytt -f ./tshirt-templates/large/redis.yaml -v redisName=$redisName -v workloadNamespace=$workloadNamespace >> ./$outputDir/redis.yaml
fi

# Apply resources to the cluster

echo "Applying inputs to the cluster"

#kubectl create ns $serviceNamespace
#kubectl create ns $workloadNamespace
#kubectl apply -f ./mysql.yaml

#kubectl apply -f ./rmq.yaml

#echo ' '
#echo "Waiting for MySQL and RabbitMQ instances to spin up."

#kubectl wait --for=condition=ready --timeout=300s pod -l app.kubernetes.io/instance=$mySQLName -n $serviceNamespace 
#kubectl wait --for=condition=ready --timeout=300s pod -l app.kubernetes.io/name=$rabbitMQName -n $serviceNamespace


#if [ "$useKNativeEventing" == "yes" ]
#then
#    kubectl apply -f ./kneventing.yaml
#fi

#kubectl apply -f ./workloads.yaml