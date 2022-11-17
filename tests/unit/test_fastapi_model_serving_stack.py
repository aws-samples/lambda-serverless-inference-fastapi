import aws_cdk as core
import aws_cdk.assertions as assertions

from fastapi_model_serving.fastapi_model_serving_stack import FastapiModelServingStack

# example tests. To run these tests, uncomment this file along with the example
# resource in fastapi_model_serving/fastapi_model_serving_stack.py
def test_sqs_queue_created():
    app = core.App()
    stack = FastapiModelServingStack(app, "fastapi-model-serving")
    template = assertions.Template.from_stack(stack)

#     template.has_resource_properties("AWS::SQS::Queue", {
#         "VisibilityTimeout": 300
#     })
