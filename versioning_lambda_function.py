import boto3
import json
from datetime import datetime, timezone
from botocore.exceptions import ClientError


s3 = boto3.client("s3")
config = boto3.client("config")


def get_classification(bucket_name):
    try:
        response = s3.get_bucket_tagging(Bucket=bucket_name)

        for tag in response.get("TagSet", []):
            if tag["Key"] == "DataClassification":
                return tag["Value"]

        return None

    except ClientError as error:
        if error.response["Error"]["Code"] == "NoSuchTagSet":
            return None

        raise


def versioning_enabled(bucket_name):
    response = s3.get_bucket_versioning(Bucket=bucket_name)

    return response.get("Status") == "Enabled"


def evaluate_bucket(bucket_name):
    classification = get_classification(bucket_name)

    if classification != "Test":
        return (
            "NOT_APPLICABLE",
            "Bucket is not classified as a Test bucket."
        )

    if not versioning_enabled(bucket_name):
        return (
            "NON_COMPLIANT",
            "Test bucket must have versioning enabled."
        )

    return (
        "COMPLIANT",
        "Test bucket has versioning enabled."
    )


def lambda_handler(event, context):
    print("Received AWS Config event:")
    print(json.dumps(event))

    invoking_event = json.loads(event["invokingEvent"])

    configuration_item = invoking_event.get(
        "configurationItem"
    )

    if not configuration_item:
        print("No configuration item received.")
        return

    resource_type = configuration_item["resourceType"]
    resource_id = configuration_item["resourceId"]

    if resource_type != "AWS::S3::Bucket":
        compliance = "NOT_APPLICABLE"
        annotation = "Rule only evaluates S3 buckets."

    elif configuration_item.get(
        "configurationItemStatus"
    ) == "ResourceDeleted":
        compliance = "NOT_APPLICABLE"
        annotation = "Bucket has been deleted."

    else:
        compliance, annotation = evaluate_bucket(
            resource_id
        )

    config.put_evaluations(
        Evaluations=[
            {
                "ComplianceResourceType": resource_type,
                "ComplianceResourceId": resource_id,
                "ComplianceType": compliance,
                "Annotation": annotation,
                "OrderingTimestamp": datetime.now(
                    timezone.utc
                )
            }
        ],
        ResultToken=event["resultToken"]
    )

    print(
        f"Bucket: {resource_id} | "
        f"Result: {compliance} | "
        f"{annotation}"
    )

    return {
        "bucket": resource_id,
        "compliance": compliance
    }