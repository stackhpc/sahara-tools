#!/bin/bash

# Register all resources necessary to create a spark cluster using sahara.

OS_DISTRO=${OS_DISTRO:-ubuntu}
case $OS_DISTRO in
    ubuntu)
        DIB_RELEASE=${DIB_RELEASE:-trusty}
        ;;
    centos7)
        ;;
    *)
        echo "Unexpected OS_DISTRO $OS_DISTRO"
        exit 1
        ;;
esac
SPARK_VERSION=${SPARK_VERSION:-1.6.0}
SPARK_VERSION_HEAT=$(echo ${SPARK_VERSION} | sed -e 's/\./-/g')
IMAGE_NAME=${IMAGE_NAME:-sahara-spark-${SPARK_VERSION}-${OS_DISTRO}${DIB_RELEASE:+-${DIB_RELEASE}}}
case $OS_DISTRO in
    centos7)
        IMAGE_USERNAME=centos
        ;;
    *)
        IMAGE_USERNAME=$OS_DISTRO
        ;;
esac
NODE_GROUP_NAME_MASTER=${NODE_GROUP_NAME_MASTER:-spark-${SPARK_VERSION_HEAT}-master}
NODE_GROUP_NAME_SLAVE=${NODE_GROUP_NAME_SLAVE:-spark-${SPARK_VERSION_HEAT}-slave}
CLUSTER_TEMPLATE_NAME=${CLUSTER_TEMPLATE_NAME:-spark-${SPARK_VERSION_HEAT}}
CLUSTER_NAME=${CLUSTER_NAME:-spark-${SPARK_VERSION_HEAT}-${OS_DISTRO}${DIB_RELEASE:+-${DIB_RELEASE}}}
FLAVOR=${FLAVOR:-compute-A}
NUM_SLAVES=${NUM_SLAVES:-2}
KEYPAIR_NAME=${KEYPAIR_NAME:-alaska-gate}
NETWORK_NAME=${NETWORK_NAME:-ilab}

# Display spark plugin.
openstack dataprocessing plugin show spark
openstack dataprocessing plugin configs get spark ${SPARK_VERSION}

# Image registration.
if ! openstack dataprocessing image show ${IMAGE_NAME} >/dev/null 2>&1; then
    openstack dataprocessing image register \
        ${IMAGE_NAME} \
        --username ${IMAGE_USERNAME}
    openstack dataprocessing image tags add \
        ${IMAGE_NAME} \
        --tags spark ${SPARK_VERSION}
fi

# Create a node group templates.
if ! openstack dataprocessing node group template show ${NODE_GROUP_NAME_MASTER} >/dev/null 2>&1; then
    openstack dataprocessing node group template create \
        --name ${NODE_GROUP_NAME_MASTER} \
        --plugin spark \
        --plugin-version ${SPARK_VERSION} \
        --processes namenode datanode master slave \
        --flavor ${FLAVOR}
fi
if ! openstack dataprocessing node group template show ${NODE_GROUP_NAME_SLAVE} >/dev/null 2>&1; then
    openstack dataprocessing node group template create \
        --name ${NODE_GROUP_NAME_SLAVE} \
        --plugin spark \
        --plugin-version ${SPARK_VERSION} \
        --processes datanode slave \
        --flavor ${FLAVOR}
fi

# Create a cluster template.
if ! openstack dataprocessing cluster template show ${CLUSTER_TEMPLATE_NAME} >/dev/null 2>&1; then
    openstack dataprocessing cluster template create \
        --name ${CLUSTER_TEMPLATE_NAME} \
        --node-groups ${NODE_GROUP_NAME_MASTER}:1 \
        ${NODE_GROUP_NAME_SLAVE}:${NUM_SLAVES} \
        --autoconfig
fi

# Create a cluster.
if ! openstack dataprocessing cluster show ${CLUSTER_NAME} >/dev/null 2>&1; then
    openstack dataprocessing cluster create \
        --name ${CLUSTER_NAME} \
        --cluster-template ${CLUSTER_TEMPLATE_NAME} \
        --image ${IMAGE_NAME} \
        --user-keypair ${KEYPAIR_NAME} \
        --neutron-network ${NETWORK_NAME}
fi
