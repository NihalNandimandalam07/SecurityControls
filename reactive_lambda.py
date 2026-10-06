import boto3
import json

s3 = boto3.client("s3")


def lambda_handler(event, context):

    print("Received remediation event:")
    print(json.dumps(event))

    bucket_name = event.get("bucketName")

    if not bucket_name:
        raise ValueError("bucketName was not provided")

    # Double-check classification before making any change
    try:
        response = s3.get_bucket_tagging(Bucket=bucket_name)

        classification = None

        for tag in response.get("TagSet", []):
            if tag["Key"] == "DataClassification":
                classification = tag["Value"]
                break

    except s3.exceptions.ClientError as error:
        if error.response["Error"]["Code"] == "NoSuchTagSet":
            classification = None
        else:
            raise

    print(f"Bucket: {bucket_name}")
    print(f"Classification: {classification}")

    if classification != "Test":
        print("Bucket is not classified as a Test bucket. No remediation performed.")

        return {
            "bucket": bucket_name,
            "action": "NO_ACTION",
            "reason": "Bucket is not classified as a Test bucket"
        }

    # Check current versioning
    response = s3.get_bucket_versioning(
        Bucket=bucket_name
    )

    status = response.get("Status")

    print(f"Current versioning status: {status}")

    if status == "Enabled":
        print("Versioning already enabled.")

        return {
            "bucket": bucket_name,
            "action": "NO_ACTION",
            "reason": "Versioning already enabled"
        }

    # Remediation
    s3.put_bucket_versioning(
        Bucket=bucket_name,
        VersioningConfiguration={
            "Status": "Enabled"
        }
    )

    print(f"Versioning enabled on {bucket_name}")

    return {
        "bucket": bucket_name,
        "action": "REMEDIATED",
        "message": "Bucket versioning enabled"
    }