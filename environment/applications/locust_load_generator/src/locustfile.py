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

from locust import  HttpUser, between, task
from common import config



class SaxmlUser(HttpUser):
    wait_time = between(3, 3)

    @task
    def smoke_test(self):

        request = {
            "prompt": "Who are you?"
        }
        with self.client.post("/generate", json=request, catch_response=True) as resp:
            print('**************')
            print(resp)
            resp.request_meta["context"]["num_output_tokens"] = 100
            resp.request_meta["context"]["model_name"] = self.environment.parsed_options.test_id
            resp.request_meta["context"]["model_method"] = "lm.Generate"
            resp.request_meta["context"]["num_input_tokens"] = 200

