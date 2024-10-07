---
# clusterissuer-lets-encrypt-production.yaml
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-production
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: tsanghan@gmail.com
    privateKeySecretRef:
      name: letsencrypt-production
    solvers:
    - dns01:
        route53:
          region: ap-southeast-1
          role: ${cert_manager_role_arn}
          auth:
            kubernetes:
              serviceAccountRef:
                name: cert-manager