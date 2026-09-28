#!/usr/bin/env python3
"""Generates the frozen-clock SigV4 presigned-URL test vector for
SigV4PresignerTest (backend/feedback-service).

The Java presigner must reproduce these URLs byte-for-byte. boto3/botocore is
the reference implementation: in the R2 investigation the identical boto3-minted
presigned PUT succeeded against Cloudflare R2 where every Java SDK attempt
failed, so its output is the canonical form R2 accepts.

The clock is frozen at 2013-05-24T00:00:00Z (the date of AWS's own SigV4 doc
examples) so the vectors are deterministic. Credentials are AWS's documented
example keys, safe to commit.
"""
import datetime
import sys

import botocore.auth


class FrozenDatetime(datetime.datetime):
    @classmethod
    def now(cls, tz=None):
        return datetime.datetime(2013, 5, 24, 0, 0, 0, tzinfo=datetime.timezone.utc)

    @classmethod
    def utcnow(cls):
        return cls.now()


botocore.auth.datetime.datetime = FrozenDatetime

import boto3  # noqa: E402  (import after the patch on purpose)
from botocore.config import Config  # noqa: E402

ENDPOINT = "https://exampleaccount.r2.cloudflarestorage.com"
REGION = "auto"
ACCESS_KEY = "AKIAIOSFODNN7EXAMPLE"
SECRET_KEY = "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY"
BUCKET = "feedback-photos"

s3 = boto3.client(
    "s3",
    endpoint_url=ENDPOINT,
    region_name=REGION,
    aws_access_key_id=ACCESS_KEY,
    aws_secret_access_key=SECRET_KEY,
    config=Config(s3={"addressing_style": "path"}, signature_version="s3v4"),
)

vectors = {
    "GET (view URL, 3600s)": s3.generate_presigned_url(
        "get_object", Params={"Bucket": BUCKET, "Key": "reports/1/2b3f9a5e-8c41-4d67-9a01-c3d5e7f9a0b1.jpg"}, ExpiresIn=3600
    ),
    "PUT with Content-Type (upload, 600s)": s3.generate_presigned_url(
        "put_object",
        Params={
            "Bucket": BUCKET,
            "Key": "reports/1/2b3f9a5e-8c41-4d67-9a01-c3d5e7f9a0b1.jpg",
            "ContentType": "image/jpeg",
        },
        ExpiresIn=600,
    ),
}

for name, url in vectors.items():
    print(f"== {name}")
    print(url)
    print()
