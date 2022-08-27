#!/bin/bash

set -e

echo "./setup.sh - This script is idempotent and will leave you in your desired
state if run multiple times. Some API calls to Vault will produce errors if
you run multiple times. Those errors can be safely ignored."

echo # newline

echo "Get Vault root token from vault-recovery-keys secret..."
ROOT_TOKEN="$(oc get secret vault-recovery-keys -o jsonpath='{.data.recovery-keys\.json}' | base64 -d | jq -r '.["root_token"]')"

echo "Log into Vault with the root token..."
# Output to /dev/null so it doesn't print the root token.
# If you hit issues, try removing "> /dev/null"
oc exec -i -n vault-server vault-server-0 -- vault login - <<< "$ROOT_TOKEN" > /dev/null

echo "Executing setup.sh in vault-server-0 pod..."
oc exec -i -n vault-server vault-server-0 -- /bin/bash -s << "EOF"
CLUSTER_NAME="kubernetes"

echo "Enabling $CLUSTER_NAME kubernetes auth engine..."
vault auth enable -path="$CLUSTER_NAME" kubernetes

echo "Configuing $CLUSTER_NAME kubernetes auth engine..."
vault write "auth/$CLUSTER_NAME/config" \
    token_reviewer_jwt="$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)" \
    kubernetes_host="https://$KUBERNETES_PORT_443_TCP_ADDR:443" \
    kubernetes_ca_cert="@/var/run/secrets/kubernetes.io/serviceaccount/ca.crt"

# Get the kubernetes auth engine accessor
AUTH_ACCESSOR=$(vault auth list -format=json | /tmp/bin/jq -r ".\"$CLUSTER_NAME/\".accessor")

echo "Writing $CLUSTER_NAME policy..."
vault policy write "$CLUSTER_NAME" - << EOF2
path "$CLUSTER_NAME/data/{{identity.entity.aliases.$AUTH_ACCESSOR.metadata.service_account_namespace}}/*" {
   capabilities=["read","list"]
}
EOF2

echo "Add $CLUSTER_NAME kv secret engine ..."
vault secrets enable -version=2 -path="$CLUSTER_NAME" kv
EOF

# configure-namespace() {
#    vault write \
#        "auth/$CLUSTER_NAME/role/admin" \
#        bound_service_account_names= \
#        bound_service_account_namespaces=vault-server \
#        policies=admin
#        ttl=60m
# }
