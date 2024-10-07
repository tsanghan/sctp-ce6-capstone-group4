---
# clusterissuer-lets-encrypt-staging.yaml
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-staging
spec:
  acme:
    server: https://acme-staging-v02.api.letsencrypt.org/directory
    email: tsanghan@gmail.com
    privateKeySecretRef:
      name: letsencrypt-staging
    solvers:
    - dns01:
        route53:
          region: ap-southeast-1
          role: ${CERT_MANAGER_ROLE_ARN}
          auth:
            kubernetes:
              serviceAccountRef:
                name: cert-manager