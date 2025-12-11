# CKAN for OpenShift — User Guide

## Table of Contents

- [Overview](#overview)
- [App Components](#app-components)
- [Setup](#setup)
  - [Pre-requisites](#pre-requisites)
  - [Pre-install](#pre-install)
  - [Configuration](#configuration)
- [Deployment](#deployment)

## Overview

This repository adapts the official [ckan-docker](https://github.com/ckan/ckan-docker) repository for the Openshift platform. It was tested on Openshift but the setup provided should equally work on a Kubernetes cluster, as long as the OpenShift route is replaced by something like a public service.

The Helm chart in this repository deploys CKAN 2.11.3 by default. It uses Postgres 16 for the database, Solr for indexing and searching, Redis for background job queueing, and has a ckan-worker pod and XLoader configured to automatically push structured data into the DataStore. For more information on the CKAN app, see the [documentation for CKAN 2.11](https://docs.ckan.org/en/2.11/).

The main technologies used in this repository are Docker, Kubernetes, Openshift, and Helm. Some familiarity with these technologies is assumed, especially Docker. If you are unable to pull from the private quay repository used by default in the Helm chart, you can build the custom CKAN image yourself using files provided in this repository.

## App Components

The CKAN app is broken down into five components for running in the microservice architecture of Kubernetes/OpenShift. See the subfolders in /ckan-chart for a breakdown.

Only the ckan-base and ckan-worker components require a custom image — in fact, these two containers use the same image with different deployment manifests. The files to build this image are in /ckan-base.

The Postgres container uses an official image provided by Crunchy, the operator which will manage the Postgres database.

The Redis image is the official one from Docker Hub.

The Solr image is the official ckan/ckan-solr image from Docker Hub.

## Setup

### Pre-requisites

This document assumes you have an Openshift cluster set up and access to the cluster through a command-line tool like **kubectl** or **oc**. You'll also need Helm installed in the cluster, since we'll be installing CKAN using a Helm chart. These instructions were tested using Helm 3. Finally, you'll need Git to clone this repository locally.

The Postgres pods in this deployment are managed by the [Crunchy Postgres operator](https://access.crunchydata.com/documentation/postgres-operator/latest). Managing Postgres through an Operator is recommended for simplifying scaling, backups, etc. Install Crunchy Postgres using their documentation [here](https://access.crunchydata.com/documentation/postgres-operator/latest/installation).

### Pre-install

Before configuring and installing CKAN, the route for exposing CKAN beyond the cluster must be created separately. Clone this repository into a command-line where you have access to your cluster, `cd` into this repository, then run `oc apply -f pre-install/`. This will create a route called `ckan` pointing to the `ckan` service, which does not exist yet.

Next, run `oc get route ckan` and save the value in the HOST/PORT column. This value is required to populate an environment variable in the ckan Helm chart. Note that since we applied it manually, the route is not part of your Helm installation. Running `helm uninstall ckan` will delete all ckan components except for the route.

### Configuration

The following files contain notable configuration options you might want to change before deploying the Helm chart:
- /ckan-chart/values.yaml
- /ckan-chart/templates/ckan-base/ckan-secret.yaml
- /ckan-chart/templates/postgres/ckandbuser-secret.yaml
- /ckan-chart/templates/postgres/datastore-user-secret.yaml

This section will only point out configurations you **must** take note of and likely customize before CKAN will run on your cluster, as well as notes for customizing credentials.

First, we'll use the value of the route you copied earlier. Inside values.yaml, ckan.env.CKAN_SITE_URL must be set to "https://" concatenated with your route. For example, if your route is `ckan-incineroar-landorus.com`, set `CKAN_SITE URL = "https://ckan-incineroar-landorus.com"`.


Still in values.yaml, you'll notice that both ckan.deployment.image and ckan-worker.deployment.image point to an image in a private quay repository. If you are unable access this repository, you can build the image for yourself using the files in the /ckan-base folder. Use the following command if you're building with Docker:

```
docker build -t ckan-base-image --build-arg XLOADER_VERSION=2.2.0 --build-arg TZ=UTC --platform linux/amd64 .
```

Push the image to container registry of your choice and modify ckan.deployment.image and ckan-worker.deployment.image to point to your image.

The final configuration you must change is inside ckan-secret.yaml. In order for XLoader to work — specifically, to allow XLoader jobs running in the ckan-worker pod to make HTTPS requests to the main ckan pod running the web app — you must set CKAN_CA_CERT to the your cluster's certificate.

To obtain the certificate, run the following from a command-line within your cluster:

```
openssl s_client -connect <your-ckan-route>:443 -showcerts
```

Copy the final certificate (the final block delimited by `-----BEGIN CERTIFICATE-----` and `-----END CERTIFICATE-----`) and paste it into ckan-secret.yaml.

The default passwords in the Helm chart are insecure. There are three sets of credentials you might want to change.

First, to change the CKAN sysadmin username and password, modify CKAN_SYSADMIN_NAME and CKAN_SYSADMIN_PASSWORD in ckan-secret.yaml.

The two other sets of credentials are for Postgres database users. In order to change these, you'll have to modify both the values that get passed into Postgres and the values that get passed into CKAN.

For example, to change the username and password for the the user currently named ckandbuser, start by modifying ckandbuser-secret.yaml. Change both instances of `ckandbuser` to your new username and modify the stringData.password field to change the password. This will update the credentials passed into the Postgres database.

Then, in ckan-secret.yaml, modify CKAN_DB_USER and CKAN_DB_PASSWORD accordingly. This will update the credentials passed into CKAN. In the same file, also update the affected URLs (CKAN_SQLALCHEMY_URL, CKAN_DATASTORE_WRITE_URL, and CKAN_DATASTORE_READ_URL).

You can update the credentials for the user currently named datastore similarly.

## Deployment

In order to deploy, run the following command from the root of this repository (within the proper namespace and cluster):

```
helm install ckan ./ckan-chart
```

The ckan and ckan-worker pods may take a few minutes to start up, as they are configured to wait until Postgres, Redis, and Solr are ready. If the ckan and ckan-worker pods refuse to start up indefinitely, this means at least one of the other three components is failing.

Check the logs for the ckan pod. If you see something similar to the following at the end of the logs, the CKAN web app is ready:

```
WSGI app 0 (mountpoint='') ready in 5 seconds on interpreter 0x556483e31620 pid: 68 (default app)
mountpoint already configured. skip.
WSGI app 0 (mountpoint='') ready in 5 seconds on interpreter 0x556483e31620 pid: 69 (default app)
mountpoint already configured. skip.
```

Check the logs for the ckan-worker pod. If you see something similar to the following at the end of the logs, the worker is ready, which means XLoader jobs will run:

```
2025-12-03 18:01:11,004 INFO [ckan.lib.jobs] Worker rq:worker:17d3a80e31584cc7a94e4c7ce86e98cb (PID 60) has started on queue(s) "default"
```

CKAN should now be accessible through your browser at the route you created. Again, you can obtain the value of the route by running `oc get route ckan`.