# 📋kproximate — Fork

This repository is a fork of the upstream *kproximate* project: [github.com/jedrw/kproximate](https://github.com/jedrw/kproximate)

The original README and installation instructions have been preserved below.
Note that this fork **does not publish pre-built images** — you will need to build them yourself using the provided Dockerfile.
*Build instructions have been added to the documentation.*

## Motivation

The upstream project relies on TLS-encrypted communication with a RabbitMQ instance delivered by the Bitnami RabbitMQ Helm chart.
Since Bitnami assets are no longer available, this fork switches to an alternative RabbitMQ chart as a workaround.

## Modifications

**🔵CloudPirates RabbitMQ chart**

This fork uses the CloudPirates RabbitMQ chart instead of the Bitnami one: [see on Artifact Hub](https://artifacthub.io/packages/helm/cloudpirates-rabbitmq/rabbitmq), [see on GitHub](https://github.com/CloudPirates-io/helm-charts/tree/main/charts/rabbitmq)

**🟠Self-managed RabbitMQ option**

An option to disable the RabbitMQ subchart installation has been added, allowing you to manage RabbitMQ independently if desired.

**🟡RabbitMQ TLS made optional**

The source code has been updated to make TLS connections to RabbitMQ optional.
This is controlled via the `rabbitMQTLS` environment variable, which can be set through the `kproximate.config.rabbitMQTLS: true/false` Helm value.

TLS is disabled by default to align with the defaults of the CloudPirates RabbitMQ chart.

**🟢Private registry support**

This fork assumes you will build your own container images.
The Helm chart has therefore been updated to support private registries and custom image names.

## Building images

A single Dockerfile builds both images by specifying the `COMPONENT` build argument.

```bash
# Controller image
docker build \
  --build-arg COMPONENT=controller \
  --build-arg TARGETARCH=amd64 \
  --tag kproximate-controller:custom .

# Worker image
docker build \
  --build-arg COMPONENT=worker \
  --build-arg TARGETARCH=amd64 \
  --tag kproximate-worker:custom .
```
You can use the provided `build.sh` script to build and push both images in a single command.
All arguments are required.

```bash
./build.sh \
  --controller kproximate-controller \
  --worker kproximate-worker \
  --registry registry.example.com/myproject \
  --tag custom
```

# 📘kproximate

A node autoscaler project for Proxmox allowing a Kubernetes cluster to dynamically scale across a Proxmox cluster.

- Polls for unschedulable pods
- Assesses the resource requirements from the requests of the unschedulable pods
- Provisions VMs from a user defined template
- User configurable cpu, memory and ssh key for provisioned VMs
- Removes nodes when requested resources can be satisfied by fewer VMs

The operator is required to create a Proxmox template configured to join the kubernetes cluster automatically on it's first boot. All examples show how to do this with K3S, however other kubernetes cluster flavours theoretically could be used if you are prepared to put in the work to build an appropriate template.

While it is a pretty niche project, some possible use cases include:

- Providing overflow capacity for a raspberry Pi cluster
- Running multiple k8s clusters each with fluctuating loads on a single proxmox cluster
- Something someone else thinks of that I haven't
- Just because...

## Configuration and Installation

See [here](./examples) for example setup scripts and configuration.

## Scaling

Kproximate polls the kubernetes cluster by default every 10 seconds looking for unschedulable resources.

> [!IMPORTANT]
> Scaling is calculated based on pod requests. Resource **requests must be set** for all pods in the cluster which are not fixed to control plane nodes else the cluster may be left with continually pending pods.

## Scaling Up

Kproximate will scale upwards as fast as it can provision VMs in the cluster limited by the amount of worker replicas deployed. As soon as unschedulable CPU or memory resource requests are found kproximate will assess the resource requirements and provision Proxmox VMs to satisfy them.

Scaling events are asyncronous so if new resources requests are found on the cluster while a scaling event is in progress then an additional scaling event will be triggered if the initial scaling event will not be able to satisfy the new resource requests.

## Proxmox Host Targeting

To select a Proxmox host for a new kproximate node all Proxmox hosts in the cluster are assessed and the following logic is applied:

- Skip host if there is an existing scaling event targeting it
- Skip host if there is an existing kproximate node on it
- Select host as target for scaling event

If no host has been selected after all hosts have been assessed then the host with the most available memory is selected.

## Scaling Down

Scaling down is very agressive. When the cluster is not scaling and the cluster's load is calculated to be satisfiable by n-1 nodes while also remaining within the configured load headroom value then a negative scale event is triggered. The node with the least allocated resources is selected and all pods are evicted from it before it is removed from the cluster and deleted.

## Template Updates

It is recommended to include either some kind of timestamp or a version in the name of your Proxmox template so that kproximate can detect which nodes to replace when the template has been updated. Once a new template has been created and kproximate has been re-deployed with updated config which includes the new template name then any nodes using the old template will be replaced one by one.

## Node Labels

Nodes can labeled with dynamic values only known at provisioning time using go templating language in a configuration option. Currently this is limited to a single templatable value `TargetHost` which is the name of the proxmox host that the kproximate node will be provisioned on. More options may be added in the future as more use cases appear. See [example-values.yaml](https://github.com/jedrw/kproximate/tree/main/examples/example-values.yaml) for an example.

## Metrics

A metrics endpoint is provided at `kproximate.kproximate.cluster.svc.local/metrics` by default. The following metrics are provided in Prometheus format with CPU measured in [CPU units](https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/#meaning-of-cpu) and memory measured in bytes:

`kpnodes_total`
<br>
The total number of kproximate nodes

`kpnodes_running`
<br>
The total number of running kproximate nodes

`cpu_provisioned_total`
<br>
The total provisioned cpu

`memory_provisioned_total`
<br>
The total memory provisioned

`cpu_allocatable_total`
<br>
The total cpu allocatable

`memory_allocatable_total`
<br>
The total memory allocatable

`cpu_allocated_total`
<br>
The total cpu allocated

`memory_allocated_total`
<br>
The total memory allocated
