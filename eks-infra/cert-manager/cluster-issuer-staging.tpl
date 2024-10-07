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
          role: ${cert_manager_role_arn}
          auth:
            kubernetes:
              serviceAccountRef:
                name: cert-manager