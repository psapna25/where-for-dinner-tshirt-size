#!/bin/bash

default_tshirt_size=small
default_workload_namespace=workloads
default_service_namespace=service-instances
default_rabbit_name=rmq-where-for-dinner
default_db_type=mysql
default_db_name=where-for-dinner
default_redis_name=redis-where-for-dinner
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
# Use 'web' workload type
#
   printf 'Use web workload type: yes/no (default %s)? ' "'yes'"

   read useWebType

   if [ -z "$useWebType" ]
   then
      useWebType='yes'
   fi 

#
# Use 'test' supplying
#
   printf 'Use test/scan supply chain: yes/no (default %s)? ' "'no'"

   read useTestScan

   if [ -z "$useTestScan" ]
   then
      useTestScan='no'
   fi 

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

       printf 'Database Instance Name (default %s): ' "'$defaultDBFullName'"
    
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
   printf '   Use web type: %s\n' "[$useWebType]"
   printf '   Use test/scan supply chain: %s\n' "[$useTestScan]"  
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

rm -rf ./$outputDir/* -y 

ytt -f ./tshirt-templates/common/rmqCluster.yaml -v rabbitMQName=$rabbitMQName -v serviceNamespace=$serviceNamespace >> ./$outputDir/rmqCluster.yaml
ytt -f ./tshirt-templates/common/rmqResourceClaim.yaml -v rabbitMQName=$rabbitMQName -v serviceNamespace=$serviceNamespace -v workloadNamespace=$workloadNamespace >> ./$outputDir/rmqResourceClaim.yaml
ytt -f ./tshirt-templates/$tshirtSize/workloads.yaml -v rabbitMQName=$rabbitMQName -v serviceNamespace=$serviceNamespace -v workloadNamespace=$workloadNamespace -v dbType=$dbType -v dbName=$dbName -v redisName=$redisName  -v useWebType=$useWebType -v useTestScan=$useTestScan >> ./$outputDir/workloads.yaml

if [ "$tshirtSize" == "medium" ] || [ "$tshirtSize" == "large" ]
then
  dbInstanceFile=$dbType'Instance.yaml'
  dbClaimFile=$dbType'ResourceClaim.yaml'

  ytt -f ./tshirt-templates/medium/$dbInstanceFile -v dbName=$dbName -v serviceNamespace=$serviceNamespace >> ./$outputDir/$dbInstanceFile
  ytt -f ./tshirt-templates/medium/$dbClaimFile -v dbName=$dbName -v serviceNamespace=$serviceNamespace -v workloadNamespace=$workloadNamespace >> ./$outputDir/$dbClaimFile

fi

if [ "$tshirtSize" == "large" ]
then
  ytt -f ./tshirt-templates/large/redis.yaml -v redisName=$redisName -v workloadNamespace=$workloadNamespace >> ./$outputDir/redis.yaml
fi

# Write to an install file
echo "export serviceNamespace=$serviceNamespace
export outputDir=$outputDir
export workloadNamespace=$workloadNamespace
export tshirtSize=$tshirtSize
export redisName=$redisName
export dbInstanceFile=$dbInstanceFile
export dbType=$dbType
export dbName=$dbName
export dbClaimFile=$dbClaimFile
export rabbitMQName=$rabbitMQName

./deployEx.sh"  >> ./$outputDir/runInstall.sh

chmod +x ./$outputDir/runInstall.sh
cp ./tshirt-templates/common/deployEx.sh ./$outputDir/deployEx.sh
chmod +x ./$outputDir/deployEx.sh

# Apply resources to the cluster

echo ' '
printf 'Install T-Shirt components now: yes/no (default %s)? ' "yes"

read install

if [ -z "$install" ]
then
    install=yes
fi

if [ "$install" == "yes" ] 
then
  cd $outputDir
  ./runInstall.sh
fi

printf "\n\nTo run or re-run the component install, 'cd' to the %s directory and run './runInstall.sh'" "'$outputDir'"
echo ' '