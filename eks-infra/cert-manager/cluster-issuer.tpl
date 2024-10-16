---
# clusterissuer-lets-encrypt.yaml
# Staging: https://acme-staging-v02.api.letsencrypt.org/directory
# Production: https://acme-v02.api.letsencrypt.org/directory
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-${ENVIRONMENT}
spec:
  acme:
    server: ${ACME_SERVER}
    email: tsanghan@gmail.com
    privateKeySecretRef:
      name: letsencrypt-${ENVIRONMENT}
    solvers:
    - dns01:
        route53:
          region: ${AWS_REGION}
          role: ${CERT_MANAGER_ROLE_ARN}
          auth:
            kubernetes:
              serviceAccountRef:
                name: cert-manager