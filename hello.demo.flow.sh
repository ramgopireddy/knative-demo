# Application Architecture Choices : Monolith, 2 Tier Architectures, N-Tier Architectures, Cloud Native, Micro-services, Serverless
# History : Needs of Serverless
# Knative
# Typical Application Requirements : Deployment, HPA, Service, and Route

# Knative
# HPA does not scale down to zero. KPA can do that

# Knative has few things
  # Knative Serving
  # Knative Eventing
  # Knative Functions
  # Knative CLI

# Show where to download the command line tools

#Install OpenShift Serverless Operator from operator Hub - This is cluster wide operator

#once installation is complete, create the KnativeServing custom resource
oc create -f knative-serving.yaml

# Cretae and change t/globalhe project
oc new-project serving-demo

# Create a Service
kn service create hello-knative \
--image="quay.io/naveenkendyala/quarkus-demo-quarkusjvm-hello:v1"

kn service list

# Send traffic and talk about the container concurrency
hey -c 50 -z 10s https://hello-knative-serving-demo.apps.cluster-gh257.gh257.sandbox2730.opentlc.com/api/hello

# Show kpa resources and talk about the concurrency
oc get kpa

# Talk about revisions
# Update the service to a newer revision
kn service update hello-knative \
--image="quay.io/naveenkendyala/quarkus-demo-quarkusjvm-hello:v1" \
--scale-target=10 --scale-max=5 --scale-window="10s"

# Show revisions
kn revision list

# Send traffic and show the increase in pod count
hey -c 50 -z 20s https://hello-knative-serving-demo.apps.cluster-gh257.gh257.sandbox2730.opentlc.com/api/hello

# Show revisions
kn revision list

# Traffic Switching
kn service update hello-knative --traffic version01=1 --traffic version01=99
kn service update hello-knative --traffic hello-knative-00002=1 --traffic hello-knative-00001=99

# Send traffic and show the increase in pod count
hey -c 50 -z 10s https://hello-knative-serving-demo.apps.cluster-gh257.gh257.sandbox2730.opentlc.com/api/hello

# Talk about the scale down time that was different between the versions


# Generate load to the End Point
# -c  Number of workers to run concurrently. Total number of requests cannot be smaller than the concurrency level. Default is 50.
# -z  Duration of application to send requests. When duration is reached, application stops and exits. If duration is specified, n is ignored.
# Examples: -z 10s -z 3m.
hey -c 50 -z 10s https://hello-knative-serving-demo.apps.cluster-gh257.gh257.sandbox2730.opentlc.com/api/hello


# Knative control plane
# Controller gets the request : Checks to see if anything is running
# If none are running, a request is sent to the activator which instructs k8s to spin a pod
# Pod comes up online and starts serving the request
# Pod also comes with another container that sends metrics to the activator
# Activator decides if more pods are needed based on concurrency
# Activator informs the k8s
# Pods are scaled accordingly,. This continues to happen based on the set max scale



Eventing:

#Create a new project for kafka cluster
oc new-project amq-streams
#create the cluster
oc create -n amq-streams -f kafka-cluster.yaml

#Create a new project for the demo
oc new-project eventing-demo

kn service create event-display1 \
    --image quay.io/openshift-knative/knative-eventing-sources-event-display:latest \
    --scale-window 10s

kn source ping create test-ping-source \
    --schedule "*/1 * * * *" \
    --data '{"message": "Welcome to RCCL!"}' \
    --sink ksvc:event-display1

#create an in-mem channel from the ui and link to the source and svcs

#add a new kn service and link with the same event
kn service create event-display2 \
    --image quay.io/openshift-knative/knative-eventing-sources-event-display:latest \
    --scale-window=10s

#create a channel for subscription from the ui
kn channel list

#list subscriptions
kn subscription list

kn service create event-display3 \
    --image quay.io/openshift-knative/knative-eventing-sources-event-display:latest \
    --scale-window=10s

#create kafka source from yaml
oc create -f kafkasource.yaml

# generate messages to the demo kafka topic (data source)
oc -n eventing-demo run kafka-producer \
    -ti --image=quay.io/strimzi/kafka:latest-kafka-2.7.0 --rm=true \
    --restart=Never -- bin/kafka-console-producer.sh \
    --broker-list my-cluster-kafka-bootstrap.amq-streams.svc.cluster.local:9092 \
    --topic knative-demo-topic

# create a broker from the UI
kn service create event-display4 \
    --image quay.io/openshift-knative/knative-eventing-sources-event-display:latest \
    --scale-window=10s

# apply filters:
type: rccl.ship.to.shore.event
type: dev.knative.kafka.event
