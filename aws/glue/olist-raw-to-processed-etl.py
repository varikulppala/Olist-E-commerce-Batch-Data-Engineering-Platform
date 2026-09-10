import sys

from awsglue.context import GlueContext
from awsglue.job import Job
from awsglue.utils import getResolvedOptions

from pyspark.context import SparkContext
from pyspark.sql.functions import (
    col,
    trim,
    lower,
    upper,
    to_timestamp,
    when
)


# ============================================================
# 1. GET JOB PARAMETERS
# ============================================================

args = getResolvedOptions(
    sys.argv,
    [
        "JOB_NAME"
    ]
)


# ============================================================
# 2. INITIALIZE SPARK AND GLUE
# ============================================================

sc = SparkContext.getOrCreate()

glueContext = GlueContext(sc)

spark = glueContext.spark_session

job = Job(glueContext)

job.init(args["JOB_NAME"], args)


# ============================================================
# 3. CONFIGURATION
# ============================================================

RAW_BUCKET = "s3://olist-aws-batch-data-platform-adhi-2026/raw"

PROCESSED_BUCKET = (
    "s3://olist-aws-batch-data-platform-adhi-2026/processed"
)

print("Starting Olist Raw to Processed ETL Job")

print(f"Raw bucket: {RAW_BUCKET}")

print(f"Processed bucket: {PROCESSED_BUCKET}")


# ============================================================
# 4. DATASET CONFIGURATION
# ============================================================

datasets = {
    "customers": "customers",
    "geolocation": "geolocation",
    "order_items": "order_items",
    "order_payments": "order_payments",
    "order_reviews": "order_reviews",
    "orders": "orders",
    "product_category_translation": "product_category_translation",
    "products": "products",
    "sellers": "sellers"
}


# ============================================================
# 5. READ RAW CSV DATA
# ============================================================

def read_raw_dataset(dataset_name):
    """
    Read a CSV dataset from the S3 raw zone.
    """

    input_path = f"{RAW_BUCKET}/{dataset_name}/"

    print(f"Reading dataset: {dataset_name}")
    print(f"Input path: {input_path}")

    df = (
        spark.read
        .option("header", "true")
        .option("inferSchema", "true")
        .csv(input_path)
    )

    print(
        f"Dataset {dataset_name} read successfully. "
        f"Row count: {df.count()}"
    )

    return df


# ============================================================
# 6. BASIC CLEANING
# ============================================================

def clean_dataframe(df):
    """
    Apply basic cleaning to every dataset.
    """

    # Remove leading and trailing spaces
    for column_name in df.columns:
        df = df.withColumn(
            column_name,
            when(
                col(column_name).cast("string").isNotNull(),
                trim(col(column_name).cast("string"))
            ).otherwise(None)
        )

    # Remove completely duplicate rows
    df = df.dropDuplicates()

    return df


# ============================================================
# 7. DATASET-SPECIFIC TRANSFORMATIONS
# ============================================================

def transform_dataset(dataset_name, df):

    # -------------------------------
    # CUSTOMERS
    # -------------------------------
    if dataset_name == "customers":

        df = df.withColumn(
            "customer_city",
            lower(trim(col("customer_city")))
        )

        df = df.withColumn(
            "customer_state",
            upper(col("customer_state"))
        )


    # -------------------------------
    # GEOLOCATION
    # -------------------------------
    elif dataset_name == "geolocation":

        df = df.withColumn(
            "geolocation_city",
            lower(trim(col("geolocation_city")))
        )

        df = df.withColumn(
            "geolocation_state",
            upper(col("geolocation_state"))
        )


    # -------------------------------
    # ORDERS
    # -------------------------------
    elif dataset_name == "orders":

        timestamp_columns = [
            "order_purchase_timestamp",
            "order_approved_at",
            "order_delivered_carrier_date",
            "order_delivered_customer_date",
            "order_estimated_delivery_date"
        ]

        for column_name in timestamp_columns:

            if column_name in df.columns:

                df = df.withColumn(
                    column_name,
                    to_timestamp(col(column_name))
                )


    # -------------------------------
    # ORDER ITEMS
    # -------------------------------
    elif dataset_name == "order_items":

        if "shipping_limit_date" in df.columns:

            df = df.withColumn(
                "shipping_limit_date",
                to_timestamp(col("shipping_limit_date"))
            )


    # -------------------------------
    # ORDER REVIEWS
    # -------------------------------
    elif dataset_name == "order_reviews":

        timestamp_columns = [
            "review_creation_date",
            "review_answer_timestamp"
        ]

        for column_name in timestamp_columns:

            if column_name in df.columns:

                df = df.withColumn(
                    column_name,
                    to_timestamp(col(column_name))
                )


    # -------------------------------
    # PRODUCTS
    # -------------------------------
    elif dataset_name == "products":

        if "product_category_name" in df.columns:

            df = df.withColumn(
                "product_category_name",
                lower(trim(col("product_category_name")))
            )


    # -------------------------------
    # SELLERS
    # -------------------------------
    elif dataset_name == "sellers":

        df = df.withColumn(
            "seller_city",
            lower(trim(col("seller_city")))
        )

        df = df.withColumn(
            "seller_state",
            upper(col("seller_state"))
        )


    # -------------------------------
    # PRODUCT CATEGORY TRANSLATION
    # -------------------------------
    elif dataset_name == "product_category_translation":

        if "product_category_name" in df.columns:

            df = df.withColumn(
                "product_category_name",
                lower(trim(col("product_category_name")))
            )


    return df


# ============================================================
# 8. WRITE PROCESSED DATA
# ============================================================

def write_processed_dataset(dataset_name, df):
    """
    Write the cleaned dataset to the S3 processed zone as Parquet.
    """

    output_path = (
        f"{PROCESSED_BUCKET}/{dataset_name}/"
    )

    print(f"Writing dataset: {dataset_name}")
    print(f"Output path: {output_path}")

    (
        df.write
        .mode("overwrite")
        .parquet(output_path)
    )

    print(
        f"Dataset {dataset_name} "
        f"successfully written to processed zone."
    )


# ============================================================
# 9. PROCESS ALL DATASETS
# ============================================================

for dataset_name in datasets:

    print("=" * 70)

    print(
        f"Processing dataset: {dataset_name}"
    )

    # Read
    df = read_raw_dataset(dataset_name)

    # Basic cleaning
    df = clean_dataframe(df)

    # Dataset-specific transformations
    df = transform_dataset(
        dataset_name,
        df
    )

    # Show final schema
    print(
        f"Final schema for {dataset_name}:"
    )

    df.printSchema()

    # Write as Parquet
    write_processed_dataset(
        dataset_name,
        df
    )

    print(
        f"Completed processing: {dataset_name}"
    )


# ============================================================
# 10. COMPLETE JOB
# ============================================================

print("=" * 70)

print(
    "Olist Raw to Processed ETL Job completed successfully."
)

job.commit()