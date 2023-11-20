
# Copyright 2023 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

import logging
import jsonlines

from google.cloud import storage

from locust import events
from common import PubsubAdapter

test_data = []


@events.init.add_listener
def on_locust_init(environment, **kwargs):
    logging.info("INITIALIZING LOCUST ....")
    if environment.parsed_options.topic_name and environment.parsed_options.project_id:
        topic_path = f"projects/{environment.parsed_options.project_id}/topics/{environment.parsed_options.topic_name}"
        logging.info(
            f'Registering PubsubAdapter for topic: {topic_path}.')
        PubsubAdapter(environment=environment,
                      topic_path=topic_path,
                      batch_size=environment.parsed_options.message_buffer_size)
    else:
        logging.info(
            'No Pubsub topic configured. User requests will NOT be tracked. To enable tracking you must set --topic_name and --project_id parameters.')


@events.test_start.add_listener
def _(environment, **kwargs):
    global test_data

    if environment.parsed_options.test_id:
        logging.info(f"Starting test: {environment.parsed_options.test_id}")
    else:
        logging.warning("Test ID not configured. Test will not be tracked.")

    test_data = environment.parsed_options.test_id 

    client = storage.Client()
    bucket_name = environment.parsed_options.test_data.split('/')[2]
    blob_name = "/".join(environment.parsed_options.test_data.split('/')[3:])
    bucket = client.get_bucket(bucket_name) 
    blob = storage.Blob(blob_name, bucket)

    data_file_name = '/tmp/data.jsonl'
    with open(data_file_name, 'wb') as f:
        blob.download_to_file(f)
    
    test_data = []
    with jsonlines.open(data_file_name) as reader:
        for obj in reader:
            test_data.append(obj['input'])

    logging.info(f"Loaded {len(test_data)} test prompts.") 


@events.test_stop.add_listener
def _(environment, **kwargs):
    logging.info(f"Stopping test: {environment.parsed_options.test_id}")


@events.init_command_line_parser.add_listener
def _(parser):

    parser.add_argument("--model_id", type=str, include_in_web_ui=True, default="", help="Model ID")
    parser.add_argument("--test_id", type=str, include_in_web_ui=True, default="", help="Test ID")
    parser.add_argument("--topic_name", type=str, env_var="TOPIC_NAME",
                        include_in_web_ui=False, default="",  help="Pubsub topic name")
    parser.add_argument("--project_id", type=str, env_var="PROJECT_ID",
                        include_in_web_ui=False, default="",  help="Project ID")
    parser.add_argument("--test_data", type=str, env_var="TEST_DATA",
                        include_in_web_ui=True, default="", help="GCS URI to test data")
    parser.add_argument("--message_buffer_size", type=int, env_var="MESSAGE_BUFFER_SIZE",
                        include_in_web_ui=True, default=5, help="The size of the batch for Pubsub transactions")
