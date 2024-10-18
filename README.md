# Capstone Project - Cohort 6 Group 4
[![CICD](https://github.com/tsanghan/sctp-ce6-capstone-group4/actions/workflows/CICD.yaml/badge.svg)](https://github.com/tsanghan/sctp-ce6-capstone-group4/actions/workflows/CICD.yaml) [![Now I am become Death, the Destroyer of Worlds](https://github.com/tsanghan/sctp-ce6-capstone-group4/actions/workflows/destroyer.yaml/badge.svg)](https://github.com/tsanghan/sctp-ce6-capstone-group4/actions/workflows/destroyer.yaml)

## Team member: Wong Tsang Han

### Capstone Project: Use Case 2 - Monitoring Large Application (SRE - Site Reliability Engineering) - A Recap

You are working in a large company that develops enterprise software solutions.

The solutions are implemented with the microservices architecture. With it, comes manifold complexity in systems’ health monitoring.

There is urgency to detect and flag out systems and applications failure early, provide traceable logs to respective engineers for troubleshooting.

Your role as a Site Reliability Engineer is to provide monitoring capabilities that are observable and traceable to stakeholders.

#### Project Completion Criteria:
* No CI/CD Required
* Only one environment suffix.
* Application deployment must be containerized
* Applications logging must be centrally managed.
* Systems health must be centrally managed.
* Produce a dashboard that shows applications and systems logs.
#

# Capstone Project: Introduction

The above section describe Capstone Project Use Case 2.

This report will be in 2 parts, `Part 1` will be describing the steps and mechanism to achieve Project Completion Criteria.

`Part 2` will describe the extra components above and beyond Project Completion Criteria to make this project more `complete`.

## Part 1

The Architecture Diagram is show below.

![Architecture Diagram](/assets/images/sctp-ce6-capstone.png)

`Amazon Elastic Kubernetes Service (Amazon EKS)` has been chosen to be the container orchestration platform.

We will be using `AWS CloudWatch` service for centralized logging solution.

`Application Monitoring Dashboard` will be created within `AWS CloudWatch` service as a requirement for the capstone projects.

We will be using Google microservices-demo `Online Boutique` as containerized application to be deployed into our `EKS` platform.

Google microservices-demo GitHub repository is at `https://github.com/GoogleCloudPlatform/microservices-demo`

The `deployment` of `EKS` is via `OpenTofu` with `main.tf` configuration file in [`aws-infra/`](/aws-infra/)

Creation of `vpc` to house the `EKS` worker nodes is via `vpc.tf` file.

The configuration/logic of `EKS` cluster/control-plane, managed-node-groups, dashboards & alarms are further abstracted into various TF configuration files located in [`aws-infra/modules/`](/aws-infra/modules/)

### EKS

For the purpose of sending Systems and Applications logs to centralized logging solution i.e., `Amazon CloudWatch`, 2 customizations of TF configuration utilizing [`module "eks"`](https://registry.terraform.io/modules/terraform-aws-modules/eks/aws/latest) have been done.

1) Define `cluster_enabled_log_types` with an `array/list` value of `["audit", "api", "authenticator", "controllerManager", "scheduler"]` [line 32 of aws-infra/modules/make_eks/main.tf](/aws-infra/modules/make_eks/main.tf#L32). Default value is `[ "audit", "api", "authenticator" ]`

2) Define [`amazon-cloudwatch-observability`](/aws-infra/modules/make_eks/main.tf#L42), an `EKS` add-on, with a [`configuration_values`](/aws-infra/modules/make_eks/main.tf#L44) pointing to [`amazon-cloudwatch-observability.json`](/aws-infra/modules/make_eks/json/amazon-cloudwatch-observability.json) add-on configuration file with `.agent.config.logs.metrics_collected.kubernetes.enhanced_container_insights` key set to a boolean value of `true`.

The following command will be handy to get the available configuration schema for the various add-ons,

```bash
aws eks describe-addon-configuration --addon-name <add-on name> --addon-version  <add-on version> | yq '.configurationSchema' | yq -P | less
```

Add-ons version can be retrieved via the following command,

```bash
aws eks describe-addon-versions --addon-name <add-on name> | less
```

*Note: I have `AWS_DEFAULT_OUTPUT=yaml` in my environment.*

Item #1 above will turn on all Kubernetes systems/cluster logs and sent to `Amazon CloudWatch` service and into a `Log Group` with name
* `/aws/eks/<Cluster_Name>/cluster`

Item #2 above will deploy `amazon-cloudwatch-observability` add-on, which consists of `FluentBit` DaemonSet that will collect Application Logs from `kubelet`[^1] and sent the logs to `Amazon CloudWatch`. The Log Groups create are as follow,
* `/aws/containerinsights/<Cluster_Name>/application`
* `/aws/containerinsights/<Cluster_Name>/performance`
* `/aws/containerinsights/<Cluster_Name>/dataplane`

[^1]: [How nodes handle container logs](https://kubernetes.io/docs/concepts/cluster-administration/logging/#how-nodes-handle-container-logs)

`FluentBit` will requires an identity to authenticate and to have the authorization to make AWS API calls to `Amazon CloudWatch` service for sending Application Logs.
The mechanism for authentication and authorization for a Kubernetes Pod to make AWS API calls to an AWS Service is via `IAM Roles for Service Account`.

Steps in creating an `IRSA` are as follow,
1) [Create an IAM OIDC provider for your cluster](https://docs.aws.amazon.com/eks/latest/userguide/enable-iam-roles-for-service-accounts.html)
2) [Assign IAM roles to Kubernetes service accounts](https://docs.aws.amazon.com/eks/latest/userguide/associate-service-account-role.html)
3) Annotate a Kubernetes Service Account with the `IAM Role` and configure this Service Account for Pods.

However, in utilizing [`module "eks"`](/aws-infra/modules/make_eks/main.tf#L20), the above process are done automatically, all we need to supply as a variable to `module "eks"` is a [`Role ARN`](/aws-infra/modules/make_eks/main.tf#L1) resource to variable named [`service_account_role_arn`](/aws-infra/modules/make_eks/main.tf#L43) in [`amazon-cloudwatch-observability`](/aws-infra/modules/make_eks/main.tf#L42) add-on.

The `dashboards` TF configuration for `CloudWatch` is in the file [/aws-infra/modules/dashboards/main.tf](/aws-infra/modules/dashboards/main.tf)
4 dashboards are created for the Capstone Project. They are as follows,
1) <Cluster_Name>-dashboard-apps
2) <Cluster_Name>-dashboard-container-insights
3) <Cluster_Name>-dashboard-performance-monitoring
4) <Cluster_Name>-dashboard-systems

`dashboard-container-insights` and `dashboard-performance-monitoring` are `CloudWatch automatic dashboards`, dashboards that is created when `.agent.config.logs.metrics_collected.kubernetes.enhanced_container_insights` is set to boolean value `true`.

However, the `CloudWatch automatic dashboards` reside in the `AWS CloudWatch Console` under the `Container Insights` menu and not in my custom Dashboard.
Fortunately, we can export the automatic dashboards in `Container Insights` menu as `json` configuration. I then import the automatic dashboards `json` configuration into my [`/aws-infra/modules/dashboards/main.tf`](/aws-infra/modules/dashboards/main.tf) TF configuration file.

`dashboard-systems` is being referenced from an `Medium` article titled [`Amazon EKS- etcd monitoring and alerting using Container Insights`](https://marcincuber.medium.com/amazon-eks-etcd-monitoring-and-alerting-using-container-insights-b1db833b4a46)

`dashboard-apps` is the dashboard I created with 3 charts.

With the above TF configuration setting and standing up an `EKS` cluster via `GitHub Workflow` (GitHub Workflow will be discussed in `Part 2`) and deployment of `Google microservices-demo Online Boutique` (deployment of `Google microservices-demo Online Boutique` is via `Fluxcd` GitOps, will be discussed in `Part 2`) and allowing the included `loadgenerator` pod to have  time to generate requests, we will have sufficient logs data to generate our 3 custom charts show below.

AWS CloudWatch will also have the following resources created,

Log Groups

![Log Groups](/assets/images/log_groups.png)

Dashboards

![Dashboards](/assets/images/dashboards.png)

The following section will discuss the `dashboard-apps` which is show below.

![Charts](/assets/images/charts.png)

The above 3 Charts was created in `dashboard-apps` as a show case on how to utilize `Log Insights` `Query` syntax for filtering and extracting information to create charts.

For creating the custom Charts, I referenced the following documentations.
1) The [`CloudWatch Logs Insights query syntax`](https://docs.aws.amazon.com/AmazonCloudWatch/latest/logs/CWL_QuerySyntax.html) with [`Tutorial`](https://docs.aws.amazon.com/AmazonCloudWatch/latest/logs/CWL_AnalyzeLogData_Tutorials.html) and [`Sample queries`](https://docs.aws.amazon.com/AmazonCloudWatch/latest/logs/CWL_QuerySyntax-examples.html)
2) The [`Filter pattern syntax for metric filters, subscription filters, filter log events, and Live Tail`](https://docs.aws.amazon.com/AmazonCloudWatch/latest/logs/FilterAndPatternSyntax.html#regex-expressions)

Before we dive into the Query syntax for creating the Charts, let us understand the log format that is sent by `FluentBit`

Log sample 1

```json
{
    "time": "2024-10-14T13:06:03.927848496Z",
    "stream": "stdout",
    "_p": "F",
    "log": "{\"http.req.id\":\"66ff9a42-0357-42fb-9719-5d8ef6d917f1\",\"http.req.method\":\"GET\",\"http.req.path\":\"/_healthz\",\"http.resp.bytes\":2,\"http.resp.status\":200,\"http.resp.took_ms\":0,\"message\":\"request complete\",\"session\":\"x-readiness-probe\",\"severity\":\"debug\",\"timestamp\":\"2024-10-14T13:06:03.927694525Z\"}",
    "log_processed": {
        "http.req.id": "66ff9a42-0357-42fb-9719-5d8ef6d917f1",
        "http.req.method": "GET",
        "http.req.path": "/_healthz",
        "http.resp.bytes": 2,
        "http.resp.status": 200,
        "http.resp.took_ms": 0,
        "message": "request complete",
        "session": "x-readiness-probe",
        "severity": "debug",
        "timestamp": "2024-10-14T13:06:03.927694525Z"
    },
    "kubernetes": {
        "pod_name": "frontend-66f586f9f8-n4fdg",
        "namespace_name": "demoapp",
        "pod_id": "1d60d257-8463-428d-8694-bb5ff45840f1",
        "host": "ip-10-42-121-248.ap-southeast-1.compute.internal",
        "container_name": "server",
        "docker_id": "9e1421fa541f126144e6339fa6312ff4e8bd68d915adb68896ab4071ca262d12",
        "container_hash": "us-central1-docker.pkg.dev/google-samples/microservices-demo/frontend@sha256:25a61a274264640e3449f8799b2d3be87a91e3df2367e4edbed608c6e01821da",
        "container_image": "us-central1-docker.pkg.dev/google-samples/microservices-demo/frontend:v0.10.1"
    }
}
```
Log sample 2

```json
{
    "time": "2024-10-14T13:07:08.495921737Z",
    "stream": "stdout",
    "_p": "F",
    "log": "{\"severity\":\"info\",\"time\":1728911228495,\"pid\":1,\"hostname\":\"paymentservice-dd7fcf5d4-6zpbp\",\"name\":\"paymentservice-charge\",\"message\":\"Transaction processed: visa ending 4799     Amount: USD278.960000000\"}",
    "log_processed": {
        "severity": "info",
        "time": 1728911228495,
        "pid": 1,
        "hostname": "paymentservice-dd7fcf5d4-6zpbp",
        "name": "paymentservice-charge",
        "message": "Transaction processed: visa ending 4799     Amount: USD278.960000000"
    },
    "kubernetes": {
        "pod_name": "paymentservice-dd7fcf5d4-6zpbp",
        "namespace_name": "demoapp",
        "pod_id": "a794d8de-2f79-4d1a-ae41-67a823b4ec19",
        "host": "ip-10-42-121-248.ap-southeast-1.compute.internal",
        "container_name": "server",
        "docker_id": "ef7a19f1c3b9be3525cda829a81838624c6e5e4625be9973233a9f7070c43a04",
        "container_hash": "us-central1-docker.pkg.dev/google-samples/microservices-demo/paymentservice@sha256:64df556b6fb98e258e7e51f06ac0780564c34b021cc2749aa65b2eae6c9fd6ae",
        "container_image": "us-central1-docker.pkg.dev/google-samples/microservices-demo/paymentservice:v0.10.1"
    }
}
```

It seems that `FluentBit` will wrap an unified envelop log format in `json` around the various logs format collected from diverse applications.
In both `Log sample 1` and `Log sample 2` the applications (`frontend` & `paymentservice`) log format are in `json`, however the salient content is the value in the `http.resp.status` key for `frontend` application and `message` key for `paymentservice` application.

To extract the `http.resp.status` value, the following `Query` [syntax](/aws-infra/modules/dashboards/json/dashboard-apps.tftpl#L10) was used.

```bash
SOURCE '/aws/containerinsights/tsanghan-ce6/application' | fields @message | filter @message like /frontend/ | filter @message like /http.resp.status/ | parse @message \"status\\\":*,\" as code | stats count(*) by code
```

The values collected (`stats count(*) by code`) are then visualized as `Pie` chart.

For the [`Transaction processed by Currency (Application Log)`](/aws-infra/modules/dashboards/json/dashboard-apps.tftpl#L23) and [`Transaction Amount by Currency (Application Log)`](/aws-infra/modules/dashboards/json/dashboard-apps.tftpl#L36) the following `Query` syntax are used.

```bash
SOURCE '/aws/containerinsights/tsanghan-ce6/application' | fields log_processed.message | filter log_processed.message like /Transaction processed/ | parse log_processed.message /Amount: (?<currency>[A-Z]{3}?)/ | stats count(*) by currency
```

```bash
SOURCE '/aws/containerinsights/tsanghan-ce6/application' | fields log_processed.message | filter log_processed.message like /Transaction processed/ | parse log_processed.message /Amount: (?<currency>[A-Z]{3}?)(?<amount>[0-9.]{10,13}?)/ | stats sum(amount) by currency
```

Both query looks similar, both utilizing `CloudWatch regex` language syntax (`/Amount: (?<currency>[A-Z]{3}?)/`) where `(?...?)` is a `named capture group` with the name being specified within `<...>` and `[A-Z]{3}` is the `regex` syntax for matching `currency code` while `(?<amount>[0-9.]{10,13}?)` capture the `currency amount`.
The statistics calculation also differ by one using `count(*)` and another using `sum(*)`, thus yielding 2 different bar charts.

## Part 2

Extra! Extra!

![Extra! Extra!](/assets/images/News-Boy-Image-GraphicsFairy-768x780.jpg)[^4]: https://thegraphicsfairy.com/terms-copyright/

To have a `feel` of a `complete` project, I have implemented the following extra requirements,
1) Deploy `Google microservices demo application` via `GitOps` using `FluxCD`.
    1) Deployment via `kind: Kustomization` & `kind: GitRepository` resource.
    2) Enable `cymbal-branding`, `network-policies` & `non-public-frontend` `Kustomization Components`.
2) `Expose` Google microservices demo application via [`Gateway API`](https://gateway-api.sigs.k8s.io/) with [`Envoy Gateway`](https://gateway.envoyproxy.io/) controller implementation.
3) Deploy [`Cert-Manager`](https://cert-manager.io/) for automatic TLS certificate requests to [`Lets' Encrypt`](https://letsencrypt.org/)
4) Deploy [`External DNS`](https://kubernetes-sigs.github.io/external-dns/latest/) such that an `A Record` with `Subject Alternative Name (SAN) FQDN` will automatically be populated into [`AWS Route53`](https://aws.amazon.com/route53/) service.
5) With #1, #2, #3 & #4 above, we can achieve a TLS Certificate rating of `A+` from [`Qualys SSL Labs`](https://www.ssllabs.com/ssltest/)

The following table highlight the extra add-ons version that is deployed.

| Add-ons | Version | Released Date | Deployment via | Deployment Tool version |
|---------|---------|---------------|----------------|-------------------------|
| Gateway API | v1.2.0 | 4 Oct 2024 | kubectl | v1.31.1 |
| Cert-Manager | v1.16.1 | 9 Oct 2024 | Helm Chart | Helm-v3.15.3 Chart-v1.16.1 |
| External-DNS | v0.15.0 | 4 Sep 2024 | Helm Chart | Helm-v3.15.3 Chart-v1.15.0 |
| Cilium CNI   | v1.16.3 | 16 Oct 2024 | Helm Chart | Helm-v3.15.3 Chart-v1.16.3 |
| FluxCD       | v2.4.0 | 1 Oct 2024 | flux CLI | v2.4.0 |


For the purpose of the Capstone Project, no CI/CD is required. However, CI/CD is implemented in this Capstone Project repository.

There are only 2 branches in the repository, `main` and `dev`. However, no actual `Production EKS` cluster and `Development EKS` cluster are build and operational at the same time.
This is for costing reason and also not a requirement for the Capstone Project.

There are also 2 GitHub Action `Environment`, namely `main` and `dev` for the Workflow to run in.

There is no different in the workflow for `main` and `dev` branches, the deployed `EKS cluster` are identical (even thought they could be set up differently with varied parameters), except for the deployment of `cert-manager` (`cert-manager` will be discuss below) which for `dev` branch will utilize `Let's Encrypt Staging CA` while the `main` branch will enable `cert-manager` to use `Let's Encrypt Production CA`.

The `switch` between `Staging CA` and `Production CA` are store in the GitHub Action `Environment Variable` `ENVIRONMENT` with value of `staging` for `dev` branch and value of `production` for the `main` branch.

The `switching` is done via `github` context property `github.ref_name` in [`jobs.<job_id>.environment`](/.github/workflows/CICD.yaml#L21)

Creation of `Amazon EKS` is via `OpenTofu` TF configuration files in [`aws-infra`](/aws-infra/) as described in `Part 1`.

Additional details not mentioned in `Part 1` of the deployment of `Amazon EKS` is as follow,

* `Amazon EKS` is deployed using `t3.large` AMI Type (`AWS Nitro System`) and with add-on `VPC-CNI` using the following configuration,

```json
{
  "env": {
    "ENABLE_POD_ENI": "true",
    "ENABLE_PREFIX_DELEGATION": "true",
    "POD_SECURITY_GROUP_ENFORCING_MODE": "standard",
    "WARM_IP_TARGET": "7",
    "MINIMUM_IP_TARGET": "20"
  },
  "nodeAgent": {
    "enablePolicyEventLogs": "true"
  },
  "enableNetworkPolicy": "true"
}
```

This is to overcome the limitation of available number of Pods per Nodes based on the [`Amazon EC2 instance type supported maximum number of elastic network interfaces and a maximum number of IP addresses that can be assigned to each network interface.`](https://docs.aws.amazon.com/eks/latest/userguide/cni-increase-ip-addresses.html)

The following [`command`](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/AvailableIpPerENI.html) will list `supported network interfaces and IP addresses per interface` for a specific instance type. Example below shows `t3` instance type.

```bash
aws ec2 describe-instance-types \
    --filters "Name=instance-type,Values=t3.*" \
    --query "InstanceTypes[].{ \
        Type: InstanceType, \
        MaxENI: NetworkInfo.MaximumNetworkInterfaces, \
        IPv4addr: NetworkInfo.Ipv4AddressesPerInterface}" \
    --output table
```

The following is example output for instance type `t3`.

```
--------------------------------------
|        DescribeInstanceTypes       |
+----------+----------+--------------+
| IPv4addr | MaxENI   |    Type      |
+----------+----------+--------------+
|  15      |  4       |  t3.2xlarge  |
|  15      |  4       |  t3.xlarge   |
|  12      |  3       |  t3.large    |
|  6       |  3       |  t3.medium   |
|  2       |  2       |  t3.nano     |
|  2       |  2       |  t3.micro    |
|  4       |  3       |  t3.small    |
+----------+----------+--------------+
```

With the results of the table above, we can see that even for instance type `t3.2xlarge` the maximum Pods per Node is `59 (15 * 4 - 1)` much lesser then the Kubernetes defined thresholds for Pods.[^2] [^3].

[^2]: [Considerations for large clusters](https://kubernetes.io/docs/setup/best-practices/cluster-large/)
[^3]: [Kubernetes Scalability thresholds](https://github.com/kubernetes/community/blob/master/sig-scalability/configs-and-limits/thresholds.md)

The `VPC-CNI` configuration key to enable `more IP addresses to Amazon EKS nodes with prefixes` is `ENABLE_PREFIX_DELEGATION`.

The mechanism of how is this achieve is describe in [`this`](https://github.com/aws/amazon-vpc-cni-k8s/blob/master/docs/prefix-and-ip-target.md) article.

After the `Amazon EKS` is created, the Workflow will execute the instructions in [`eks-infra`](/eks-infra/).

Currently, the instructions in [`eks-infra`](/eks-infra/) are in `bash shell script` that calls `kubectl` command.

A `GitHub Action` [`Action`](https://github.com/tsanghan/setup-kubectl-action) is specifically written to setup `kubectl` in the `GitHub-Hosted runner`.



Workflow Diagram

