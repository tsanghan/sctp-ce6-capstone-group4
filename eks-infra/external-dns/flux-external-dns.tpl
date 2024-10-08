---
apiVersion: source.toolkit.fluxcd.io/v1
kind: HelmRepository
metadata:
  name: external-dns
  namespace: default
spec:
  type: default
  interval: 5m0s
  url: https://kubernetes-sigs.github.io/external-dns/
---
apiVersion: helm.toolkit.fluxcd.io/v2
kind: HelmRelease
metadata:
  name: external-dns
  namespace: default
spec:
  interval: 10m
  timeout: 5m
  chart:
    spec:
      chart: external-dns
      version: '1.15.0'
      sourceRef:
        kind: HelmRepository
        name: external-dns
      interval: 5m
  releaseName: external-dns
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
    rbac:
      create: true
    serviceAccount:
      name: "external-dns"
      automountServiceAccountToken: true
      annotations:
        "eks.amazonaws.com/role-arn": ${EXTERNAL_DNS_ROLE_ARN}
    sources:
        - service
        - ingress
        - gateway-httproute
    extraArgs:
        - --domain-filter=sctp-sandbox.com
        - --txt-owner-id=tsanghan-ce6
        - --namespace=demoapp-gw