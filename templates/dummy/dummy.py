import json
import logging

logger = logging.getLogger()
logger.setLevel(logging.INFO)


def handler(event, context):
    logger.info(event)

    return {
        'statusCode': 200,
        'body': json.dumps('Hello from Lambda!')
    }
