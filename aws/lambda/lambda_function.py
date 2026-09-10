import json
import logging
import boto3
from datetime import datetime, timezone

logger = logging.getLogger()
logger.setLevel(logging.INFO)

glue = boto3.client("glue", region_name="ap-south-1")

GLUE_JOB_NAME = "olist-raw-to-processed-etl"


def lambda_handler(event, context):

    start_time = datetime.now(timezone.utc).isoformat()

    logger.info("========================================")
    logger.info("Olist Batch Orchestrator started")
    logger.info("Start time: %s", start_time)
    logger.info("Event: %s", json.dumps(event))
    logger.info("========================================")

    try:

        response = glue.start_job_run(
            JobName=GLUE_JOB_NAME
        )

        job_run_id = response["JobRunId"]

        logger.info(
            "Glue job started successfully"
        )

        logger.info(
            "Glue Job Name: %s",
            GLUE_JOB_NAME
        )

        logger.info(
            "Glue Job Run ID: %s",
            job_run_id
        )

        result = {
            "pipeline": "olist-batch-pipeline",
            "status": "GLUE_JOB_STARTED",
            "glue_job": GLUE_JOB_NAME,
            "glue_job_run_id": job_run_id,
            "orchestrator": "aws-lambda",
            "timestamp": start_time
        }

        return {
            "statusCode": 200,
            "body": json.dumps(result)
        }

    except Exception as error:

        logger.exception(
            "Failed to start Glue job"
        )

        result = {
            "pipeline": "olist-batch-pipeline",
            "status": "FAILED",
            "error": str(error),
            "orchestrator": "aws-lambda",
            "timestamp": start_time
        }

        return {
            "statusCode": 500,
            "body": json.dumps(result)
        }