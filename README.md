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
