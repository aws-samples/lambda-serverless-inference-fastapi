import json
import logging
from fastapi import FastAPI
from mangum import Mangum

logger = logging.getLogger()
logger.setLevel(logging.INFO)

app = FastAPI(root_path="/prod")


@app.get("/")
async def root() -> dict:
    """
    **Dummy endpoint that returns 'hello world' example.**

    ```
    Returns:
        dict: 'hello world' message.
    ```
    """
    return {"message": "Hello World"}


@app.get("/question")
async def get_answer(question: str, context: str) -> dict:
    """
    **Endpoint implementing the question-answering logic.**

    ```
    Args:
        question (str): Question to be answered. Answer should be included in 'context'.
        context (str): Context containing information necessary to answer 'question'.
    Returns:
        dict: Dictionary containing the answer to the question along with some metadata.
    ```
    """
    from custom_lambda_utils.scripts.inference import question_answerer

    return question_answerer(question=question, context=context)


def lambda_handler(event, context):
    logger.info(json.dumps(event))

    asgi_handler = Mangum(app)
    response = asgi_handler(
        event, context
    )  # Call the instance with the event arguments

    logger.info(json.dumps(response))
    return response
