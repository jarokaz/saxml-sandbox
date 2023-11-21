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

from locust import  HttpUser, between, task, events
from common import config


class FastAPIStressUser(HttpUser):
    weight = 1
    wait_time = between(0.1, 0.2)

    @task
    def test_througput(self):
        request = {
            "delay": 0.2 
        }
        self.client.post("/test_throughput", json=request)


class SaxmlUser(HttpUser):
    weight = 0
    wait_time = between(3, 3)

    @task
    def smoke_test(self): 

        #print(self.environment.parsed_options.test_id)
        #print(config.test_data)
        print('****************')
        print(len(config.test_data), len(config.test_data[0]), len(config.test_data[1]))
        
        return

        request = {
            "prompt": "Who are you?"
        }
        with self.client.post("/generate", json=request, catch_response=True) as resp:
            print('**************')
            print(resp.json())
            resp_dict = resp.json()
            resp.request_meta["context"]["model_name"] = self.environment.parsed_options.test_id
            resp.request_meta["context"]["model_method"] = "lm.Generate"
            resp.request_meta["context"]["model_server_response_time"] = resp_dict["performance_metrics"]["response_time"]


#@events.test_start.add_listener
#def _(environment, **kwargs):
#    if environment.parsed_options.test_id:
#        logging.info(f"Starting test: {environment.parsed_options.test_data}")
#    else:
#        logging.warning("Test ID not configured. Test will not be tracked.")