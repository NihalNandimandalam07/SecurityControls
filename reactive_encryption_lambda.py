import boto3
import json

s3 = boto3.client("s3")


def lambda_handler(event, context):

    print("Received encryption remediation event:")
    print(json.dumps(event))

    bucket_name = event.get("bucket_name")

    if not bucket_name:
        raise ValueError("bucket_name was not provided")

    # Check current bucket encryption
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

                print(
                    f"{bucket_name} already uses SSE-KMS."
                )

                return {
                    "bucket": bucket_name,
                    "action": "NO_ACTION",
                    "reason": "SSE-KMS already enabled"
            }

    except s3.exceptions.ClientError as error:

        print(
            f"Current encryption configuration "
            f"could not be read: {error}"
        )

    # Enable SSE-KMS
    s3.put_bucket_encryption(
        Bucket=bucket_name,
        ServerSideEncryptionConfiguration={
            "Rules": [
                {
                    "ApplyServerSideEncryptionByDefault": {
                        "SSEAlgorithm": "aws:kms",
                        "KMSMasterKeyID": "alias/aws/s3"
    },
                    "BucketKeyEnabled": True
    }
    ]
    }
    )

    print(
        f"SSE-KMS encryption enabled on {bucket_name}"
    )

    return {
        "bucket": bucket_name,
        "action": "REMEDIATED",
        "encryption": "aws:kms"
    }