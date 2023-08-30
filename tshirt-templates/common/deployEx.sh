echo "Applying conponent configuration to the cluster"
kubectl create ns $serviceNamespace
kubectl create ns $workloadNamespace

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