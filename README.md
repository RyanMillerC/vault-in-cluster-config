# Vault In-Cluster Configuration

Configure Vault for in-cluster Kubernetes authentication. This configuration is
only valid when the Vault server is running on the same cluster that needs to
authenticate to Vault.

The script *setup.sh* will set up:

* Enable a k8s auth engine for the cluster
* Configure the k8s auth engine with a k8s certificate/token
* Enable a KV secret engine
* Create a policy to use for namespace segmented Vault roles

The script at the moment does not:

* Create a role for a namespace

## Running

**NOTE:** These commands assumes Vault was initialized with
[vault-init](https://github.com/RyanMillerC/vault-init) using the default set
up. If you customized or deployed Vault through other means, you may need to
make slight modifications to the commands below.

```bash
# Copy setup.sh into the Vault server container
oc rsync -n vault-server setup.sh vault-server-0:/tmp/setup.sh

# Execute setup.sh in the Vault server container
oc exec -it -n vault-server vault-server-0 -- /tmp/setup.sh
```
