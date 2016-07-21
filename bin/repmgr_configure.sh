#!/bin/bash

if [ -z "$CLUSTER_NODE_NETWORK_NAME" ]; then
    CLUSTER_NODE_NETWORK_NAME="`hostname`"
fi

# TODO docker-compose.yml could use the same -N suffix that kubernetes PetSet uses
if [ -z "$NODE_NAME" ]; then
    export NODE_NAME="`hostname`"
fi

if [ -z "$NODE_ID" ]; then
    export NODE_ID="`echo $NODE_NAME | awk -F '-' '{print $NF}'`"
fi

echo "127.0.0.1 $CLUSTER_NODE_NETWORK_NAME" >> /etc/hosts
# Need this loopback to speedup connections and also k8s doesn't have DNS loopback by service name on the same pod
# TODO not needed with PetSet? Has entries like: 172.17.0.3	postgres-0.postgres.[namespace].svc.cluster.local	postgres-0

echo "cluster=$CLUSTER_NAME
node=$NODE_ID
node_name=$NODE_NAME
conninfo='user=$REPLICATION_USER password=$REPLICATION_PASSWORD host=$CLUSTER_NODE_NETWORK_NAME dbname=$REPLICATION_DB port=$REPLICATION_PRIMARY_PORT'
failover=automatic
promote_command='PGPASSWORD=$REPLICATION_PASSWORD repmgr standby promote --log-level DEBUG --verbose'
follow_command='PGPASSWORD=$REPLICATION_PASSWORD repmgr standby follow -W --log-level DEBUG --verbose'
reconnect_attempts=$RECONNECT_ATTEMPTS
reconnect_interval=$RECONNECT_INTERVAL
master_response_timeout=$MASTER_RESPONSE_TIMEOUT
loglevel=$LOG_LEVEL
" >> /etc/repmgr.conf

chown postgres /etc/repmgr.conf

if [[ "$INITIAL_NODE_TYPE" != "master" ]]; then
    if [ -n "$REPLICATION_UPSTREAM_NODE_ID" ]; then

        if [[ "$NODE_ID" != "$REPLICATION_UPSTREAM_NODE_ID" ]]; then
            echo "upstream_node=$REPLICATION_UPSTREAM_NODE_ID" >> /etc/repmgr.conf
        else
            echo "Misconfiguration of upstream node, NODE_ID=$NODE_ID AND REPLICATION_UPSTREAM_NODE_ID=$REPLICATION_UPSTREAM_NODE_ID"
            exit 1
        fi
    else
        echo "For node with initial type $INITIAL_NODE_TYPE you have to setup REPLICATION_UPSTREAM_NODE_ID"
        exit 1
    fi
fi