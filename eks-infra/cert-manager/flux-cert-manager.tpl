---
apiVersion: source.toolkit.fluxcd.io/v1
kind: HelmRepository
metadata:
  name: cert-manager
  namespace: cert-manager
spec:
  type: default
  interval: 5m0s
  url: https://charts.jetstack.io
---
apiVersion: helm.toolkit.fluxcd.io/v2
kind: HelmRelease
metadata:
  name: cert-manager
  namespace: cert-manager
spec:
  interval: 10m
  timeout: 5m
  chart:
    spec:
      chart: cert-manager
      version: 'v1.15.3'
      sourceRef:
        kind: HelmRepository
        name: cert-manager
      interval: 5m
  releaseName: cert-manager
  install:
    remediation:
      retries: 3
  upgrade:
    remediation:
      retries: 3
  test:
    enable: true
  driftDetection:
    mode: enabled
    ignore:
    - paths: ["/spec/replicas"]
      target:
        kind: Deployment
  values:
    crds:
      enabled: true
    serviceAccount:
      name: "cert-manager"
      annotations:
        "eks.amazonaws.com/role-arn": ${CERT_MANAGER_ROLE_ARN}