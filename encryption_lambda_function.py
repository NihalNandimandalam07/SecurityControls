import boto3
import json
from datetime import datetime, timezone
from botocore.exceptions import ClientError

s3 = boto3.client("s3")
config = boto3.client("config")


def uses_sse_kms(bucket_name):
    try:
        response = s3.get_bucket_encryption(
            Bucket=bucket_name
        )

        rules = response.get(
            "ServerSideEncryptionConfiguration",
            {}
        ).get("Rules", [])

        for rule in rules:
            default_encryption = rule.get(
                "ApplyServerSideEncryptionByDefault",
                {}
            )

        algorithm = default_encryption.get(
                "SSEAlgorithm"
            )

        if algorithm == "aws:kms":
                return True

        return False

    except ClientError as error:
        error_code = error.response["Error"]["Code"]

        print(
            f"Error checking encryption for "
            f"{bucket_name}: {error_code}"
        )

        return False


def evaluate_bucket(bucket_name):

    if uses_sse_kms(bucket_name):
        return (
            "COMPLIANT",
            "S3 bucket uses SSE-KMS encryption."
        )

    return (
        "NON_COMPLIANT",
        "S3 bucket must use SSE-KMS encryption."
    )


def lambda_handler(event, context):

    print("Received AWS Config event:")
    print(json.dumps(event))

    invoking_event = json.loads(
        event["invokingEvent"]
    )

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

        compliance, 
        annotation = evaluate_bucket(
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