#!/bin/bash

set -e

CLUSTER_NAME="kubernetes"

echo "Enabling $CLUSTER_NAME kubernetes auth engine..."
vault auth enable -path="$CLUSTER_NAME" kubernetes

echo "Configuing $CLUSTER_NAME kubernetes auth engine..."
vault write "auth/$CLUSTER_NAME/config" \
    token_reviewer_jwt="$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)" \
    kubernetes_host="https://$KUBERNETES_PORT_443_TCP_ADDR:443" \
    kubernetes_ca_cert="@/var/run/secrets/kubernetes.io/serviceaccount/ca.crt"

# Get the kubernetes auth engine accessor
AUTH_ACCESSOR=$(vault auth list -format=json | jq -r ".\"$CLUSTER_NAME/\".accessor")

echo "Writing $CLUSTER_NAME policy..."
vault policy write "$CLUSTER_NAME" - << EOF
path "$CLUSTER_NAME/data/{{identity.entity.aliases.$AUTH_ACCESSOR.metadata.service_account_namespace}}/*" {
   capabilities=["read","list"]
}
EOF

echo "Add $CLUSTER_NAME kv secret engine ..."
vault secrets enable -version=2 -path="$CLUSTER_NAME" kv

# configure-namespace() {
#    vault write \
#        "auth/$CLUSTER_NAME/role/admin" \
#        bound_service_account_names= \
#        bound_service_account_namespaces=vault-server \
#        policies=admin
#        ttl=60m
# }
