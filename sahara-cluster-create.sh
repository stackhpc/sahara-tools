#!/bin/bash -e

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
PLUGIN=${PLUGIN:-spark}
case $PLUGIN in
    spark)
        PLUGIN_VERSION=${SPARK_VERSION:-1.6.0}
        ;;
    vanilla)
        PLUGIN_VERSION=${HADOOP_VERSION:-2.7.1}
        ;;
esac

PLUGIN_VERSION_HEAT=$(echo ${PLUGIN_VERSION} | sed -e 's/\./-/g')
IMAGE_NAME=${IMAGE_NAME:-sahara-${PLUGIN}-${PLUGIN_VERSION}-${OS_DISTRO}${DIB_RELEASE:+-${DIB_RELEASE}}}

# FIXME: avoid 'supporting' hadoop 2.8.0 in sahara for now.
if [[ $PLUGIN_VERSION = '2.8.0' ]]; then
    PLUGIN_VERSION='2.7.3'
    PLUGIN_VERSION_HEAT='2-7-3'
fi

case $OS_DISTRO in
    centos7)
        IMAGE_USERNAME=centos
        ;;
    *)
        IMAGE_USERNAME=$OS_DISTRO
        ;;
esac
NODE_GROUP_NAME_MASTER=${NODE_GROUP_NAME_MASTER:-${PLUGIN}-${PLUGIN_VERSION_HEAT}-master}
NODE_GROUP_NAME_SLAVE=${NODE_GROUP_NAME_SLAVE:-${PLUGIN}-${PLUGIN_VERSION_HEAT}-slave}
CLUSTER_TEMPLATE_NAME=${CLUSTER_TEMPLATE_NAME:-${PLUGIN}-${PLUGIN_VERSION_HEAT}}
CLUSTER_NAME=${CLUSTER_NAME:-${PLUGIN}-${PLUGIN_VERSION_HEAT}-${OS_DISTRO}${DIB_RELEASE:+-${DIB_RELEASE}}}
FLAVOR=${FLAVOR:-compute-A}
NUM_SLAVES=${NUM_SLAVES:-2}
case $PLUGIN in
    spark)
        MASTER_PROCESSES=${MASTER_PROCESSES:-"namenode datanode master slave"}
        SLAVE_PROCESSES=${SLAVE_PROCESSES:-"datanode slave"}
        ;;
    vanilla)
        MASTER_PROCESSES=${MASTER_PROCESSES:-"namenode datanode resourcemanager nodemanager"}
        SLAVE_PROCESSES=${SLAVE_PROCESSES:-"datanode nodemanager"}
        ;;
esac
KEYPAIR_NAME=${KEYPAIR_NAME:-alaska-gate}
NETWORK_NAME=${NETWORK_NAME:-ilab}

# Display plugin.
openstack dataprocessing plugin show ${PLUGIN}
openstack dataprocessing plugin configs get ${PLUGIN} ${PLUGIN_VERSION} || true

# Image registration.
if ! openstack dataprocessing image show ${IMAGE_NAME} >/dev/null 2>&1; then
    openstack dataprocessing image register \
        ${IMAGE_NAME} \
        --username ${IMAGE_USERNAME}
    openstack dataprocessing image tags add \
        ${IMAGE_NAME} \
        --tags ${PLUGIN} ${PLUGIN_VERSION}
fi

# Create a node group templates.
if ! openstack dataprocessing node group template show ${NODE_GROUP_NAME_MASTER} >/dev/null 2>&1; then
    openstack dataprocessing node group template create \
        --name ${NODE_GROUP_NAME_MASTER} \
        --plugin ${PLUGIN} \
        --plugin-version ${PLUGIN_VERSION} \
        --processes ${MASTER_PROCESSES} \
        --flavor ${FLAVOR}
fi
if ! openstack dataprocessing node group template show ${NODE_GROUP_NAME_SLAVE} >/dev/null 2>&1; then
    openstack dataprocessing node group template create \
        --name ${NODE_GROUP_NAME_SLAVE} \
        --plugin ${PLUGIN} \
        --plugin-version ${PLUGIN_VERSION} \
        --processes ${SLAVE_PROCESSES} \
        --flavor ${FLAVOR}
fi

# Create a cluster template.
if ! openstack dataprocessing cluster template show ${CLUSTER_TEMPLATE_NAME} >/dev/null 2>&1; then
    TMP_CONFIG=$(mktemp)
    cat > ${TMP_CONFIG} << EOF
{
    "Hadoop": {
        "hadoop.ib.enabled": true,
        "hadoop.roce.enabled": false,
        "hadoop.rdma.dev.name": "mlx5_0"
    },
    "HDFS": {
        "dfs.master": "\${yarn.nodemanager.hostname}"
    }
}
EOF
    openstack dataprocessing cluster template create \
        --name ${CLUSTER_TEMPLATE_NAME} \
        --node-groups ${NODE_GROUP_NAME_MASTER}:1 \
        ${NODE_GROUP_NAME_SLAVE}:${NUM_SLAVES} \
        --autoconfig \
        --config ${TMP_CONFIG}
    rm ${TMP_CONFIG}
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
