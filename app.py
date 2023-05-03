#!/usr/bin/env python3
import os

import aws_cdk as cdk

from fastapi_model_serving.fastapi_model_serving_stack import FastapiModelServingStack


app = cdk.App()

FastapiModelServingStack(
    app,
    "FastapiModelServingStack",
    env=cdk.Environment(
        account=os.getenv("CDK_DEFAULT_ACCOUNT"),
        region=app.node.try_get_context("DEPLOYMENT_REGION"),
    ),
)

app.synth()
