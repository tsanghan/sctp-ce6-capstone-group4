---
# clusterissuer-lets-encrypt-staging.yaml
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-"$ENVIRONMENT"
spec:
  acme:
    server: "${ACME_CERVER}"
    email: tsanghan@gmail.com
    privateKeySecretRef:
      name: letsencrypt-staging
    solvers:
    - dns01:
        route53:
          region: "$AWS_REGION"
          role: ${CERT_MANAGER_ROLE_ARN}
          auth:
            kubernetes:
              serviceAccountRef:
                name: cert-manager