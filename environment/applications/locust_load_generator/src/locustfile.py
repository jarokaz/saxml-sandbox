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

import json
import logging
import random

from locust import HttpUser, between, task, events
from common import config_metrics_tracking


class FastAPIStressUser(HttpUser):
    weight = 0
    wait_time = between(0.1, 0.2)

    @task
    def test_througput(self):
        request = {
            "delay": 0.2
        }
        self.client.post("/starlette_test_throughput", json=request)


class SaxmlUser(HttpUser):
    weight = 1
    wait_time = between(3, 3)

    @task
    def lm_generate(self):
        global test_data

        if not test_data:
            logging.error("No test data configured.")
            return

        prompt = test_data[random.randint(0, len(test_data))]
        model_options = {}
        request = {
            "prompt": prompt,
            "model_options": model_options,
        }

        self.client.post("/generate", json=request)
   #     with self.client.post("/generate", json=request, catch_response=True) as resp:
   #         print('***********')
   #         print(resp)
   #         resp_dict = resp.json()
   #         print(resp_dict)
   #         resp.request_meta["context"]["model_name"] = self.environment.parsed_options.model_id
   #         resp.request_meta["context"]["model_method"] = "lm.Generate"
   #         resp.request_meta["context"]["model_server_response_time"] = resp_dict["performance_metrics"]["response_time"]
   #         if self.environment.parsed_options.log_request_and_response:
   #             resp.request_meta["context"]["request"] = json.dumps(request)
   #             resp.request_meta["context"]["completions"] = json.dumps(resp_dict["completions"])


@events.init_command_line_parser.add_listener
def _(parser):
    parser.add_argument("--topic_name", type=str, env_var="TOPIC_NAME",
                        include_in_web_ui=False, default="",  help="Pubsub topic name")
    parser.add_argument("--project_id", type=str, env_var="PROJECT_ID",
                        include_in_web_ui=False, default="",  help="Project ID")
    parser.add_argument("--maximum_message_queue_length", type=int, env_var="MAXIMUM_MESSAGE_QUEUE_LENGTH",
                        include_in_web_ui=False, default=1000, help="The maximum size of the in-memory message queue that stages messages for publishing")
    parser.add_argument("--minimum_message_queue_length", type=int, env_var="MINIMUM_MESSAGE_QUEUE_LENGTH",
                        include_in_web_ui=False, default=10, help="The batch of messages will be published after the length of the in-memory message queue goes over this threshold")


@events.init.add_listener
def on_locust_init(environment, **kwargs):
    logging.info("INITIALIZING LOCUST ....")
    config_metrics_tracking(environment) 
