echo "Applying conponent configuration to the cluster"
kubectl create ns $serviceNamespace
kubectl create ns $workloadNamespace
kubectl label namespaces $serviceNamespace apps.tanzu.vmware.com/tap-ns=true
kubectl label namespaces $serviceNamespace tap.tanzu.vmware.com/scanpolicy=lax
kubectl label namespaces $serviceNamespace tap.tanzu.vmware.com/pipeline=java
kubectl label namespaces $workloadNamespace apps.tanzu.vmware.com/tap-ns=true
kubectl label namespaces $workloadNamespace tap.tanzu.vmware.com/scanpolicy=lax
kubectl label namespaces $workloadNamespace tap.tanzu.vmware.com/pipeline=java


kubectl apply -f ./rmqCluster.yaml

if [ "$tshirtSize" == "medium" ] || [ "$tshirtSize" == "large" ]
then

    if [ "$tshirtSize" == "large" ]
    then
        kubectl apply -f ./redis.yaml
        echo ' '
        echo "Waiting for Redis instance to spin up."
        kubectl wait --for=condition=ready --timeout=300s pod -l app=where-for-dinner-$workloadNamespace,service=$redisName -n $workloadNamespace 
    fi

    kubectl apply -f ./$dbInstanceFile
    echo ' '
    echo "Waiting for Database instance to spin up."
    echo "Sleeping for 60 seconds."
    sleep 60

    if [ "$dbType" == "mysql" ]
    then
        kubectl wait --for=condition=ready --timeout=300s pod -l app.kubernetes.io/instance=$dbName -n $serviceNamespace 
    else
        kubectl wait --for=condition=ready --timeout=300s pod -l postgres-instance=$dbName,type=data -n $serviceNamespace 
    fi

    kubectl apply -f ./$dbClaimFile

# We want to to make sure RabbitMQ is up and running before executing the knative configuration
# The duplicate of the following lines below and in the "else" below that is for operational optimization.
# We always want to get the RabbitMQ install going ASAP so we don't have to wait as long for it to start up.
    echo ' '
    echo "Waiting for RabbitMQ instance to spin up."
    kubectl wait --for=condition=ready --timeout=300s pod -l app.kubernetes.io/name=$rabbitMQName -n $serviceNamespace 

else
    echo ' '
    echo "Waiting for RabbitMQ instance to spin up."
    kubectl wait --for=condition=ready --timeout=300s pod -l app.kubernetes.io/name=$rabbitMQName -n $serviceNamespace 
fi

kubectl apply -f ./rmqResourceClaim.yaml

kubectl apply -f ./workloads.yaml

echo "Finished applying inputs to the cluster"
