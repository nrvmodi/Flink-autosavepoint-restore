
#!/bin/bash

flinkBucketPath=s3://niravmodi-test-bucket/savepoint/quota
flinkWebUiUrl=http://flink.web.internal/jobs/overview

echo 'Fetching Jobs'

curl $flinkWebUiUrl | jq '.[]' > response.json

echo 'Fetched Jobs'

jobmanagerPod=$(kubectl get pods | grep jobmanager | awk '{print $1}')

echo 'Flink Job Manager Pod: '$jobmanagerPod
jid=$(jq --raw-output '.[] | select(.name=="<<Replace_job_name>>" and .state == "RUNNING") | .jid' response.json)

echo 'Flink Job Manager Job Id: '$jid

savepointPathValue=$(kubectl exec $jobmanagerPod flink savepoint $jid $flinkBucketPath | grep s3 | awk '{print $4}')
echo 'Savepoint Path: '${savepointPathValue}

# sample value for your variables
# savepointPathVarName="SAVEPOINT"

template=`cat "quota-deployment.yaml" | sed --expression "s@{{SAVEPOINT}}@$savepointPathValue@g"`

echo "$template"

echo 'Applying generated template.....'

echo "$template" | kubectl apply -f -

echo 'Applied generated template'

echo 'Cancelling existing job: '$jid

kubectl exec $jobmanagerPod flink cancel $jid

echo 'Cancelled existing job: '$jid
