Deploy a machine learning serverless inference endpoint using FastAPI, AWS Lambda and AWS Cloud Development Kit
Introduction

For data scientists, moving machine learning models from the Proof-of-Concept stage to production presents very often a significant challenge. One of the main challenges can be deploying a well-performing, locally trained model to cloud for inference and use in other applications. It can be cumbersome to manage the process but with the right tool the required efforts could be significantly reduced.

Amazon SageMaker inference, which was made generally available in April 2022, makes it easy for you to deploy ML models into production to make predictions at scale, providing a broad selection of ML infrastructure and model deployment options to help meet all kinds of ML inference needs. You can leverage SageMaker serverless inference endpoints for workloads which have idle periods between traffic spurts and can tolerate cold starts, which scales out automatically based on traffic and takes away the undifferentiated heavy lifting of selecting and managing servers. In the meanwhile, you can choose to leverage AWS Lambda directly to expose your models and deploy your ML applications using your favourite open-source framework, which can prove to be more flexible and cost-effective. 

FastAPI is a modern, high-performance web framework for building APIs with Python. It stands out when it comes to development of serverless applications with RESTful microservices and use cases required Machine Learning inference at scale across multiple industries. Its ease and built-in functionalities like the automatic API documentation make it a very popular choice amongst machine learning engineers to deploy high-performance inference APIs using FastAPI. You could define and organize your routes using out-of-the-box functionalities from FastAPI to scale out and handle growing business logic as you need, test locally and host it on AWS Lambda then expose it through a single API Gateway, which allows you to bring open-source web framework to Lambda without heavy-lifting or refactoring your codes.

This post will show you how to easily deploy and run serverless ML inference by exposing your machine learning model as an endpoint using FastAPI, Docker, AWS Lambda and Amazon API Gateway. We will also show you how to automate the deployment using AWS Cloud Development Kit (AWS CDK). Furthermore, we will present a benchmarking of performance and cost between SageMaker serverless inference endpoint and our solution to help you understand the pros and cons and make decision based on quantitative metrics.

Architecture
The architecture of the solution we are deploying in this blog post is shown below.

 
Picture: Architecture of the solution

Prerequisites

Have Python3 installed, along with virtualenv for creating and managing virtual environments in Python.
Install aws-cdk v2 on your system in order to be able to use the aws-cdk CLI.
Have Docker installed (and, for the deployment part, running!) on your local machine.

Test if all necessary software is installed:

AWS CLI is needed. Login to your account and select the region where you want to deploy the solution.

Python3 is needed 
Python3 --version

Check if virtualenv is installed for creating and managing virtual environments in Python. Strictly speaking, this is not a hard requirement, but it will make your life easier and helps following this blog post more easily.
Python3 -m virtualenv --version


Check if cdk is installed. This will be used to deploy our solution.
cdk --version

Check if Docker is installed. Our solution will make your model accessible through a Docker image to your lambda. For building this image locally, we will need Docker.
docker --version
Also make sure it is up and running by running docker ps

How to structure your FastAPI project using AWS CDK

We are using the following directory structure for our project (ignoring some boilerplate cdk code that is immaterial in the context of this blog post):

```
fastapi_model_serving
│   
└───.venv  
│
└───fastapi_model_serving
│   │   __init__.py
│   │   fastapi_model_serving_stack.py
│   │   
│   └───model_endpoint  
│       └───docker
│       │      Dockerfile
│       │      serving_api.tar.gz
│       │  
│       └───runtime
│            └───serving_api
 │                    requirements.txt  
│                    serving_api.py
│                └───custom_lambda_utils
│                     └───model_artifacts
│                            ...
│                     └───scripts
│                            inference.py
 │  
└───templates
│   └───api
│   │     api.py    
│   └───dummy
│         dummy.py
│   
│   app.py
│   cdk.json
│   README.md
│   requirements.txt
│   init-lambda-code.sh
 
```
The directory follows the recommended structure of cdk projects for Python. 

The most important part of this repository is the fast_api_model_serving directory. It contains the code that will define the cdk stack and the resources that are going to be used for model serving.

model_endpoint directory:
•	contains all the assets necessary that will make up our serverless endpoint, i.e., Dockerfile to build the Docker image that AWS Lamdba will use, as well as the lambda function code that uses FastAPI to handle inference requests and route them to the correct endpoint, and the model artifacts of the model that we want to deploy.
Inside model endpoint, 
Docker directory:
•	which specifies a Dockerfile which is used to build the image for the lambda function with all the artifacts (lambda function code, model artifacts, ...) in the right place so that they can be used without issues.
•	Serving.api.tar.gz - this is a tarball that contains all the assets from the runtime folder that are necessary for building the Docker image. More on how to create the tar.gz. file later in the next section.
runtime directory:
•	contains the code for the serving_api lambda function and it’s dependencies specified in the requirements.txt file
•	as well as the custom_lambda_utils directory which includes an inference script that loads the necessary model artifacts so that the model can be passed to the serving_api that will then expose it as an endpoint
Besides, we have template directory which provides you with a template of folder structure and files where you can define your customised codes and APIs following the sample we went through above.

template directory:
•	contains dummy code that can be used to create new lambda functions from 
o	dummy contains the code that implements the structure of an ordinary AWS Lambda function using the Python runtime
o	api contains the code that lambda that implements an AWS Lambda function that wraps a FastAPI endpoint around an existing API Gateway


Step-by-step walk-through: Deploying the solution

NOTE: By default, the code is going to be deployed inside the eu-west-1 region. If you want to change the region to another region of your choice, you can change the DEPLOYMENT_REGION context variable in the cdk.json file.
Beware, however, that the solution tries to deploy a lambda on top of the arm64 architecture, and that this feature might not be available in all regions at the time of your reading. In this case, you need to change the “architecture” parameter in the fastapi_model_serving_stack.py file, as well as the first line of the Dockerfile inside the model_endpoint > Docker directory, to host this solution on the x86 architecture.


1)  First, run the following command to clone the git repository:
git clone <LINK-TO-REPOSITORY>
Since we would like to showcase that the solution could work with model artifacts that you train locally, we contain a sample model artifact of a pretrained DistilBERT model on the Hugging Face model hub for question answering task in the serving_api.tar.gz file. Hence, the downloading time can take around 3 to 5 minutes. 

2) Now, let’s setup the environment to recreate the blog post. This step will download the pretrained model that will be deployed from the huggingface model hub into the ./model_endpoint/runtime/serving_api/custom_lambda_utils/model_artifacts directory. It will also create a virtual environment and install all dependencies that are needed. You only need to run this command once:
make prep
This command can take around 5 minutes (depending on your internet bandwidth) because it needs to download the model artifacts.


3) The model artifacts need to be packaged inside a .tar.gz archive that will be used inside the docker image that is built in the cdk stack. You will need to run this code whenever you make changes to the model artifacts or the API itself to always have the most up-to-date version of your serving endpoint packaged:
make package_model
Finally, the artifacts are all in-place. Now we can move over to deploying the cdk stack to your AWS account.


4) FIRST TIME CDK USERS ONLY: Run cdk bootstrap if it is your first time deploying an AWS CDK app into an environment (account + region combination). This stack includes resources that are needed for the toolkit’s operation. For example, the stack includes an S3 bucket that is used to store templates and assets during the deployment process.
make cdk_bootstrap


5) Since we are building docker images locally in this cdk deployment, we need to ensure that the docker daemon is running before we are going to be able to deploy this stack via the cdk CLI. To check whether or not the docker daemon is running on your system, use the following command:
docker ps
If you don’t get an error message, you should be good to deploy the solution. 


6) Deploy the solution with the following command:
make deploy
This step can take around 5-10 minutes due to building and pushing the docker image.

Troubleshooting

If you are a Mac User
Error when logging into ECR with Docker login: "Error saving credentials ... not implemented". For example,
exited with error code 1: Error saving credentials: error storing credentials - err: exit status 1,...dial unix backend.sock: connect: connection refused
Solution
Before you can use lambda on top of Docker containers inside cdk, it might be the case that you have got to change the ~/docker/config.json file. More specifically, you might have to change the credsStore parameter in ~/.docker/config.json to osxkeychain. That solves Amazon ECR login issues on a Mac.

Running real-time inference

After your AWS Clouformation got deployed successfully, go to Outputs section and open up the endpoint url. Now our model is accessible via the endpoint url and we are ready to run real-time inference.

1) Go to the url to see if you can see “hello world” message and go to url+/docs to see if you can see the interactive swagger UI page successfully. Notice there might be some coldstart time so you may need to wait or refresh a few times.

2) Once login to the landing page of FastAPI swagger UI page, you will be able to execute via the root / or via /question. From /, you could try it out and execute the API and get the “hello world” message. 
From /question, you could try it out and execute the API and run ML inference on the model we deployed for question and answering case. Here is one example.

The question is What is the color of my car now? and the context is My car used to be blue but I painted red.

Once you click on Execute, based on the given context, the model will answer the question with response as below.

In the response body, you will be able to see the answer with the confidence score the model gives. You could also play around with other examples or embed the API in your existing application.

Alternatively, you can run the inference via code. Here is one example written in Python, using the requests library:
import requests

url = "https://<YOUR_API_GATEWAY_ENDPOINT_ID>.execute-api.<YOUR_ENDPOINT_REGION>.amazonaws.com/prod/question?question=\"What is the color of my car now?\"&context=\"My car used to be blue but I painted red\""

response = requests.request("GET", url, headers=headers, data=payload)

print(response.text)

This code snippet would output a string similar to the following:
'{"score":0.6947233080863953,"start":38,"end":41,"answer":"red"}'

Benchmarking with SageMaker serverless inference endpoint

We conducted a number of experiments in terms of performance and cost to benchmark between SageMaker serverless inference endpoint and our solution. 

First, we deployed the same DistilBERT model for question answering task with SageMaker serverless inference endpoint using the code snippet below. For simplicity, we leverage the newest version of AWS managed HuggingFace inference container listed in this repo and pull the model directly from HuggingFace model hub. Then we deploy the model without providing inference.py. If you want to reduce “cold” start time then you can also choose to upload your model artifact in S3, load the model from there with your customized inference script. In this benchmarking, we will only test the off-the-shelf native solution provided by SageMaker and won’t measure a “cold” time.

import sagemaker
from sagemaker.huggingface.model import HuggingFaceModel
from sagemaker.serverless import ServerlessInferenceConfig

# Specify Model Image_uri
image_uri=763104351884.dkr.ecr.us-west-2.amazonaws.com/huggingface-pytorch-inference:1.10.2-transformers4.17.0-cpu-py38-ubuntu20.04’

# Hub Model configuration. https://huggingface.co/models
hub = {
    'HF_MODEL_ID':'distilbert-base-cased-distilled-squad',
    'HF_TASK':'question-answering'
}

# create Hugging Face Model Class
huggingface_model = HuggingFaceModel(
    image_uri=image_uri,
    transformers_version='4.17.0',
    pytorch_version='1.10.2',
    py_version='py38',
    env=hub,
    role=sagemaker.get_execution_role(), 
)

# Specify MemorySizeInMB and MaxConcurrency
serverless_config = ServerlessInferenceConfig(
    memory_size_in_mb=6144, max_concurrency=10,
)

# deploy the serverless endpoint
predictor = huggingface_model.deploy(
    serverless_inference_config=serverless_config
)

Table 1: Comparison between SageMaker Serverless Inference Endpoint and Lambda based on performance metrics. (Applicable in regions where the services are generally available)
	SageMaker Serverless Inference Endpoint	Lambda
Memory size	For SageMaker Serverless Inference Endpoint, you can only choose from : {1024 MB, 2048 MB, 3072 MB, 4096 MB, 5120 MB, 6144 MB}	For Lambda, you can choose your memory size from 128MB to 10240 MBs by 1 MB incrementally
Ephemeral disk storage size	5GB, regardless of chosen memory size	between 128 MB and 10,240 MB (10GB) free to choose from 512 MB to 10 GB
Maximum concurrency	Maximum concurrent invocations per endpoint: 200. Total maximum concurrency depends on concurrent invocations available in region	maximum concurrency depends on concurrent invocations available in region
Cold starts	susceptible to cold starts

Performance
The first experiment we carried was the comparison of performance using latency metrics between the two solutions. Since memory size is the variable that will affect how many vCPUs SageMaker Serverless endpoint or Lambda can get access to, we fix the memory size for both SageMaker Serverless endpoint and Lambda in our solution to 6144 MBs which is the maximum size available for SageMaker Serverless inference endpoint. We eliminated the effect of concurrency execution by sending one request per time that will not invoke both solution concurrently. 

We sent 300 sequential requests to both endpoints hosted with Lambda and SageMaker serverless inference and measure the average latency from the 100th to 300th requests from the application side, making sure the factors such as cold start and concurrent invocations are eliminated for both solutions. The tests were carried out in region eu-central-1.

The average latency calculated based on the 200 sequential requests we get from application end is
•	SageMaker serverless endpoint: 141.2 ms ± 4.22 ms per loop (mean ± std. dev. of 7 runs, 1 loop each)
•	FastAPI endpoint on Lambda: 90.1 ms ± 4.25 ms per loop (mean ± std. dev. of 7 runs, 10 loops each)

In terms of total latency from application side, our solution outperforms SageMaker serverless inference endpoint around 50ms in terms of latency, which is almost a 60% improvement.

In the meanwhile, Amazon CloudWatch provides a few out-of-the-box metrics of our interests for API Gateway, Lambda and SageMaker Serverless inference. It worths noting that these metrics are not apple-to-apple comparison but could give us insights on how latency is composed.

 
Picture: Selected metrics for Lambda and SageMaker serverless inference from CloudWatch

SageMaker serverless inference endpoint: Refer to this link for more details.  
•	SageMaker - ModelLatency: The interval of time taken by a model to respond as viewed from SageMaker. This interval includes the local communication times taken to send the request and to fetch the response from the container of a model and the time taken to complete the inference in the container. The average number of ModelLatency from this benchmarking test is around 56.9 ms.
•	SageMaker - OverheadLatency: This interval is measured from the time SageMaker receives the request until it returns a response to the client, minus the ModelLatency. The average number of OverheadLatency from this benchmarking test is around 48.4 ms.

Our solution - FastAPI solution:
•	Lambda - Duration: The amount of time that your function code spends processing an event. The billed duration for an invocation is the value of Duration rounded up to the nearest millisecond. The average number of Duration from this benchmarking test is around 48.4 ms.
•	API Gateway - Integration latency: The time between when API Gateway relays a request to the backend and when it receives a response from the backend. The average number of integration latency from this benchmarking test is around 63.4ms.
•	API Gateway – Latency: The time between when API Gateway receives a request from a client and when it returns a response to the client. The average number of integration latency from this benchmarking test is around 65.8ms.

The relationship between these metrics above could be visualized in this way:
 
Picture: Built-in Cloudwatch metrics relationship

As we can see from the architecture above, the total time to process the request could be calculated as
•	SageMaker serverless solution: Total round trip time = ModelOverhead Latency + ModelLatency = 56.9ms + 48.4ms = 105.3ms
•	FastAPI solution: Total round trip time = API Gateway Latency = 65.8ms

The latency between user and the request taken to reach the first API should be similar as experiments were launched from the same place and in the same time. From the empirical results from both the application side and Cloudwatch metrics, we can draw the conclusion that our solution outperforms SageMaker serverless solution by around 60% in terms of total latency. Also since Lambda supports memory size up to 10240 MBs, which could improve performance even more. 

Cost
For cost, you are not charged for the cold start time Lambda takes for it to prepare the function but it does add latency to the overall invocation duration. Therefore we assume the processing time for both solutions is 48ms. 

With SageMaker Serverless Inference, you only pay for the compute capacity used to process inference requests, billed by the millisecond, and the amount of data processed. Therefore, we can estimate the cost of running a DistilBERT model (distilbert-base-cased-distilled-squad), with price estimates for the eu-west-1 Region) as follows:
•	Total request time – 48 ms
•	Data processed IN/OUT – $0.016 per GB
•	Data being processed – 1GB
•	Data processed IN/OUT price – $0.016 * 1 * 2 = $0.016
•	Compute cost (6144 MB) – $0.0001200 USD per second
•	1 million requests cost in total – 1,000,000 * 0.048 * $0.0001200 + $0.016 = $5.78

For our solution with Lambda, you pay for duration cost which depends on the amount of memory you allocate to your function.
•	Duration – 48 ms
•	Duration cost - $0.0000166667 for every GB-second
•	Request cost - $0.0000002 per request
•	1 million duration cost – 1,000,000 * 0.048 * 6 * $0.0000166667 = $4.80
•	1 million request cost – 1,000,000 * $0.0000002 = $0.20
•	API Gateway price - $3.5 per million requests
•	Ephemeral storage price - $0.0000000309 for every GB-second
•	1 million request cost in total - $8.5

As shown above, SageMaker serverless solution is around 45% cheaper than our solution. The estimated cost doesn’t include free tier from AWS Lambda or Amazon SageMaker. The cost is calculated in eu-west-1 Region and can be referred as an estimate only.

In conclusion, deploying your trained model using AWS Lambda gives you better latency performance and more flexibility to customize your solution and improve your performance by configuring memory size. You could leverage the AWS Free Tier and lower prices to achieve more cost-effective model deployment. AWS Lambda also enables you to reduce cold starts with provisioned concurrency. For details, refer to this blog. 

On the other hand, SageMaker serverless inference endpoint as a manageable solution, is more cost effective and is able to help reduce operational overhead and provides you with more out-of-the-box features such as production variants, more granular machine learning metrics from Cloudwatch etc, which gives you on-click experience of deploying your model. You also have cost benefits such as SageMaker savings plan which is applicable throughout the whole machine learning lifecycle including inference. 
Clean up

Inside the root directory of your repository, run:
cdk destroy
Conclusion

In this post, we introduced how you can easily use AWS Lambda to deploy your trained machine learning model using your favorite web application framework such as FastAPI. We provided you with a detailed code repository that you can deploy easily following the instructions and you retain the flexibility of switching to whichever trained model artifacts you process. The performance can depend on how the users implement and deploy the model.

More importantly, we provide a benchmarking example between our solution and SageMaker Serverless Inference to deploy Hugging Face models to showcase the pros and cons you will get out of different deployment options. This could be referenced as a guideline when you need to decide what is the best for your workloads. In the meantime, we also attached a detailed code snippet using the SageMaker Python SDK to deploy Hugging Face models with SageMaker Serverless Inference for your to replicate the benchmarking and play around with it. We then dived deep into inference latency and price performance of the two solutions. You are welcome to try out yourself and we’re excited to hear your feedback!
