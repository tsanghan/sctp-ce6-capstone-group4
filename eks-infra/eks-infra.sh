#!/usr/bin/env bash

set -eo pipefail

kubectl apply -k gateway-api

kubectl -n kube-system patch daemonset aws-node --type='strategic' -p='{"spec":{"template":{"spec":{"nodeSelector":{"io.cilium/aws-node-enabled":"true"}}}}}'

helm repo add cilium https://helm.cilium.io/
helm install cilium cilium/cilium --version 1.16.2 \
  --namespace kube-system \
  --set eni.enabled=true \
  --set ipam.mode=eni \
  --set egressMasqueradeInterfaces=eth0 \
  --set routingMode=native

flux bootstrap github \
  --token-auth \
  --owner=tsanghan \
  --repository=fleet-infra \
  --branch=main \
  --path=clusters/my-cluster \
  --personal

# kubectl create ns cert-manager --dry-run=client -oyaml | egrep -v "{}|null" | k apply -f -
kubectl apply -f cert-manager/namespace.yaml
kubectl wait --timeout=5m ns/cert-manager --for=jsonpath='{.status.phase}'=Active
kubectl apply -f cert-manager/role.yaml
kubectl apply -f cert-manager/rolebinding.yaml
# at this point `cert_manager_role_arn` & `environment` & `GITHUB_TOKEN` must be exported
envsubst < cert-manager/flux-cert-manager.tpl | kubectl apply -f -
while [ "$(kubectl get crd certificates.cert-manager.io 2> /dev/null)" = "" ]; do
  echo "waiting"
  sleep 5
done
kubectl wait --timeout=10m -n cert-manager deployment/cert-manager-webhook --for=condition=Available
envsubst < cert-manager/cluster-issuer.tpl | kubectl apply -f -

#kubectl create ns envoy-gateway-system --dry-run=client -oyaml | egrep -v "{}|null" | k apply -f -
kubectl apply -f envoygateway/namespace.yaml
kubectl wait --timeout=5m ns/envoy-gateway-system --for=jsonpath='{.status.phase}'=Active
kubectl apply -f envoygateway/flux-envoygateway.yaml
while [ "$(kubectl -n envoy-gateway-system get deployment/envoy-gateway 2> /dev/null)" = "" ]; do
  echo "waiting"; sleep 2
done
kubectl wait --timeout=10m -n envoy-gateway-system deployment/envoy-gateway --for=condition=Available
kubectl apply -f envoygateway/gateway_class.yaml
kubectl apply -f envoygateway/gateway_envoyproxy.yaml

envsubst < external-dns/flux-external-dns.tpl | kubectl apply -f -

# helm repo add jetstack https://charts.jetstack.io --force-update
# helm install \
#   cert-manager jetstack/cert-manager \
#   --namespace cert-manager \
#   --create-namespace \
#   --version v1.15.3 \
#   --set crds.enabled=true \
#   --set serviceAccount.name=cert-manager

# helm install \
#   eg oci://docker.io/envoyproxy/gateway-helm \
#   --create-namespace \
#   --namespace envoy-gateway-system \
#   --version v0.0.0-latest
