resource "aws_cloudwatch_dashboard" "apps" {
  dashboard_name = "${var.cluster_name}-dashboard-apps"

  dashboard_body = templatefile("${path.module}/json/dashboard-apps.tftpl", { region = var.region })
  # dashboard_body = jsonencode({
  #   "widgets" = [
  #     {
  #       "height" = 6
  #       "properties" = {
  #         "query"  = "SOURCE '/aws/containerinsights/tsanghan-ce6/application' | fields @message | filter @message like /frontend/ | filter @message like /http.resp.status/ | parse @message \"status\\\":*,\" as code | stats count(*) by code"
  #         "region" = var.region
  #         "title"  = "Frontend HTTP Status Code (Application Log)"
  #         "view"   = "pie"
  #       }
  #       "type"  = "log"
  #       "width" = 12
  #       "x"     = 12
  #       "y"     = 24
  #     },
  #     {
  #       "height" = 6
  #       "properties" = {
  #         "legend" = {
  #           "position" = "bottom"
  #         }
  #         "liveData" = false
  #         "metrics" = [
  #           [
  #             "ContainerInsights",
  #             "apiserver_request_total",
  #             "ClusterName",
  #             "tsanghan-ce6",
  #             {
  #               "accountId" = var.account_id
  #               "id"        = "mm1m0"
  #               "stat"      = "Sum"
  #               "yAxis"     = "left"
  #             },
  #           ],
  #           [
  #             ".",
  #             "apiserver_request_duration_seconds",
  #             ".",
  #             ".",
  #             {
  #               "accountId" = var.account_id
  #               "id"        = "mm2m0"
  #               "stat"      = "Average"
  #               "yAxis"     = "right"
  #             },
  #           ],
  #         ]
  #         "period"   = 60
  #         "region"   = var.region
  #         "timezone" = "LOCAL"
  #         "title"    = "API server requests"
  #         "yAxis" = {
  #           "left" = {
  #             "label"     = "Count"
  #             "showUnits" = false
  #           }
  #           "right" = {
  #             "label"     = "Seconds"
  #             "showUnits" = false
  #           }
  #         }
  #       }
  #       "type"  = "metric"
  #       "width" = 12
  #       "x"     = 12
  #       "y"     = 0
  #     },
  #     {
  #       "height" = 6
  #       "properties" = {
  #         "legend" = {
  #           "position" = "bottom"
  #         }
  #         "liveData" = false
  #         "metrics" = [
  #           [
  #             "ContainerInsights",
  #             "apiserver_admission_controller_admission_duration_seconds",
  #             "ClusterName",
  #             "tsanghan-ce6",
  #             {
  #               "accountId" = var.account_id
  #               "id"        = "mm1m0"
  #               "stat"      = "Average"
  #               "yAxis"     = "left"
  #             },
  #           ],
  #           [
  #             ".",
  #             "etcd_request_duration_seconds",
  #             ".",
  #             ".",
  #             {
  #               "accountId" = var.account_id
  #               "id"        = "mm2m0"
  #               "label"     = "etcd_request_duration_seconds (alpha)"
  #               "stat"      = "Average"
  #               "yAxis"     = "right"
  #             },
  #           ],
  #         ]
  #         "period"   = 60
  #         "region"   = var.region
  #         "timezone" = "LOCAL"
  #         "title"    = "API server admission controller duration / ETCD request duration"
  #         "yAxis" = {
  #           "left" = {
  #             "label"     = "Seconds"
  #             "showUnits" = false
  #           }
  #           "right" = {
  #             "label"     = "Seconds"
  #             "showUnits" = false
  #           }
  #         }
  #       }
  #       "type"  = "metric"
  #       "width" = 12
  #       "x"     = 0
  #       "y"     = 6
  #     },
  #     {
  #       "height" = 6
  #       "properties" = {
  #         "legend" = {
  #           "position" = "bottom"
  #         }
  #         "liveData" = false
  #         "metrics" = [
  #           [
  #             "ContainerInsights",
  #             "apiserver_storage_objects",
  #             "ClusterName",
  #             "tsanghan-ce6",
  #             {
  #               "accountId" = var.account_id
  #               "id"        = "mm1m0"
  #               "region"    = var.region
  #               "stat"      = "Maximum"
  #               "yAxis"     = "left"
  #             },
  #           ],
  #           [
  #             "ContainerInsights",
  #             "apiserver_storage_size_bytes",
  #             "ClusterName",
  #             "tsanghan-ce6",
  #             {
  #               "accountId" = var.account_id
  #               "id"        = "mm2m0"
  #               "region"    = var.region
  #               "stat"      = "Maximum"
  #               "yAxis"     = "right"
  #             },
  #           ],
  #         ]
  #         "period"   = 60
  #         "region"   = var.region
  #         "stacked"  = false
  #         "timezone" = "LOCAL"
  #         "title"    = "API server storage objects"
  #         "view"     = "timeSeries"
  #         "yAxis" = {
  #           "left" = {
  #             "label"     = "Count"
  #             "showUnits" = false
  #           }
  #           "right" = {
  #             "label"     = "Bytes"
  #             "showUnits" = false
  #           }
  #         }
  #       }
  #       "type"  = "metric"
  #       "width" = 12
  #       "x"     = 0
  #       "y"     = 0
  #     },
  #     {
  #       "height" = 6
  #       "properties" = {
  #         "legend" = {
  #           "position" = "bottom"
  #         }
  #         "liveData" = false
  #         "metrics" = [
  #           [
  #             "ContainerInsights",
  #             "rest_client_requests_total",
  #             "ClusterName",
  #             "tsanghan-ce6",
  #             {
  #               "accountId" = var.account_id
  #               "id"        = "mm1m0"
  #               "label"     = "rest_client_requests_total (alpha)"
  #               "stat"      = "Sum"
  #               "yAxis"     = "left"
  #             },
  #           ],
  #           [
  #             "ContainerInsights",
  #             "rest_client_request_duration_seconds",
  #             "ClusterName",
  #             "tsanghan-ce6",
  #             {
  #               "accountId" = var.account_id
  #               "id"        = "mm2m0"
  #               "label"     = "rest_client_request_duration_seconds (alpha)"
  #               "stat"      = "Average"
  #               "yAxis"     = "right"
  #             },
  #           ],
  #         ]
  #         "period"   = 60
  #         "region"   = var.region
  #         "stacked"  = false
  #         "timezone" = "LOCAL"
  #         "title"    = "REST client requests"
  #         "view"     = "timeSeries"
  #         "yAxis" = {
  #           "left" = {
  #             "label"     = "Count"
  #             "showUnits" = false
  #           }
  #           "right" = {
  #             "label"     = "Seconds"
  #             "showUnits" = false
  #           }
  #         }
  #       }
  #       "type"  = "metric"
  #       "width" = 12
  #       "x"     = 12
  #       "y"     = 6
  #     },
  #   ]
  # })
}

resource "aws_cloudwatch_dashboard" "systems" {
  dashboard_name = "${var.cluster_name}-dashboard-systems"

  dashboard_body = templatefile("${path.module}/json/dashboard-systems.tftpl", { cluster_name = var.cluster_name, account_id = var.account_id })
}

resource "aws_cloudwatch_dashboard" "performance-monitoring" {
  dashboard_name = "${var.cluster_name}-dashboard-performance-monitoring"

  dashboard_body = templatefile("${path.module}/json/dashboard-performance-monitoring.tftpl", { region = var.region, account_id = var.account_id })
}

resource "aws_cloudwatch_dashboard" "container-insights" {
  dashboard_name = "${var.cluster_name}-dashboard-container-insights"

  dashboard_body = templatefile("${path.module}/json/dashboard-container-insights.tftpl", { region = var.region })
}
