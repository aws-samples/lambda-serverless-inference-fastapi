import sys
import os
import logging

logger = logging.getLogger()
logger.setLevel(logging.INFO)

try:
    sys.path.append(os.environ["LAMBDA_TASK_ROOT"])
except KeyError:
    logger.warning(
        """Environment variable "LAMBDA_TASK_ROOT" not found.
        Assuming execution outside of lambda environment."""
    )

from transformers import pipeline, AutoModelForQuestionAnswering, AutoTokenizer


DIR_PATH = os.path.dirname(os.path.realpath(__file__))
PATH_TO_MODEL_ARTIFACTS = os.path.join(DIR_PATH, "..", "model_artifacts/")


model = AutoModelForQuestionAnswering.from_pretrained(PATH_TO_MODEL_ARTIFACTS)
tokenizer = AutoTokenizer.from_pretrained(PATH_TO_MODEL_ARTIFACTS)

question_answerer = pipeline(
    task="question-answering", model=model, tokenizer=tokenizer
)
