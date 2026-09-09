resource "aws_s3_bucket" "olist_data" {
  bucket = "olist-aws-batch-data-platform-adhi-2026"
}

resource "aws_s3_bucket_versioning" "olist_data" {
  bucket = aws_s3_bucket.olist_data.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "olist_data" {
  bucket = aws_s3_bucket.olist_data.id

  block_public_acls       = true
  ignore_public_acls      = true
  block_public_policy     = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "olist_data" {
  bucket = aws_s3_bucket.olist_data.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }

    bucket_key_enabled = true
  }
}

resource "aws_glue_job" "olist_etl" {
  name = "olist-raw-to-processed-etl"

  role_arn = "arn:aws:iam::970722351160:role/AWSGlueServiceRole-OlistDataPlatform"

  description = "AWS Glue PySpark ETL job to clean and transform raw Olist datasets from the S3 raw zone and write processed datasets to the S3 processed zone."

  glue_version      = "5.1"
  worker_type       = "G.1X"
  number_of_workers = 2
  execution_class   = "STANDARD"

  timeout     = 480
  max_retries = 0

  execution_property {
    max_concurrent_runs = 1
  }

  command {
    name            = "glueetl"
    script_location = "s3://aws-glue-assets-970722351160-ap-south-1/scripts/olist-raw-to-processed-etl.py"
    python_version  = "3"
  }

  default_arguments = {
    "--enable-metrics"                   = ""
    "--enable-spark-ui"                  = "true"
    "--spark-event-logs-path"            = "s3://aws-glue-assets-970722351160-ap-south-1/sparkHistoryLogs/"
    "--enable-job-insights"              = "true"
    "--enable-observability-metrics"     = "true"
    "--conf"                             = "spark.eventLog.rolling.enabled=true --conf spark.sql.catalog.glue_catalog.glue.skip-name-validation=true"
    "--enable-glue-datacatalog"          = ""
    "--enable-continuous-cloudwatch-log" = "true"
    "--job-bookmark-option"              = "job-bookmark-disable"
    "--job-language"                     = "python"
    "--TempDir"                          = "s3://aws-glue-assets-970722351160-ap-south-1/temporary/"
  }
}
