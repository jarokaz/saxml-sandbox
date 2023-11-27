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
from locust.runners import  MasterRunner
from common import config_metrics_tracking
from common import load_test_prompts


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
            "model_id": self.environment.parsed_options.model_id, 
            "model_options": model_options,
        }
        #self.client.post("/generate", json=request, context={"request": json.dumps(request)}) 
        self.client.post("/generate", json=request) 


@events.init_command_line_parser.add_listener
def _(parser):
    parser.add_argument("--model_id", type=str, env_var="MODEL_ID",
                        include_in_web_ui=True, default="/sax/test/llama7bfp16tpuv5e",  help="Model ID")
    parser.add_argument("--test_data_uri", type=str, env_var="TEST_DATA_URI",
                        include_in_web_ui=True, default="gs://jk-saxml-archive/test_data/orca_prompts.jsonl", help="GCS URI to test data")

@events.test_start.add_listener
def _(environment, **kwargs):
    if not isinstance(environment.runner, MasterRunner):
        global test_data
        logging.info(f"Loading test prompts from {environment.parsed_options.test_data_uri}")
        test_data = []
        test_data = load_test_prompts(environment.parsed_options.test_data_uri)


@events.init.add_listener
def _(environment, **kwargs):
    logging.info("INITIALIZING LOCUST ....")
    config_metrics_tracking(environment) 
