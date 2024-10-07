---
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: envoyproxy
  namespace: demoapp-gw
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt-${environment}
spec:
  gatewayClassName: envoy
  listeners:
    - name: http
      hostname: "cymbal.sctp-sandbox.com"
      port: 80
      protocol: HTTP
      allowedRoutes:
        namespaces:
          from: Selector
          selector:
            matchLabels:
              kubernetes.io/metadata.name: demoapp
    - name: https
      hostname: "cymbal.sctp-sandbox.com"
      port: 443
      protocol: HTTPS
      tls:
        mode: Terminate
        certificateRefs:
        - kind: Secret
          name: demoapp-tls
      allowedRoutes:
        namespaces:
          from: Selector
          selector:
            matchLabels:
              kubernetes.io/metadata.name: demoapp