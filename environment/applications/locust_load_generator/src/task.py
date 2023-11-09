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

import os
import json
import random
import time

import sax

from functools import partial, update_wrapper
from locust import User, task, between

from locust.runners import MasterRunner, WorkerRunner, LocalRunner
from locust.runners import STATE_STOPPING, STATE_STOPPED, STATE_CLEANUP, STATE_RUNNING


LOG_STATS_INTERVAL_SEC = 5
LOG_NAME = 'locust'


def lm_generate_task(
        user:object,
        model:str,
):
    """
    Calls lm.Generate method on the model.
    """

    elapsed_time = 100 + random.randint(1,50)
    output_tokens = 50 + random.randint(1, 50)
    simulate_exception = random.randint(1, 10)

    exception = None
    if simulate_exception > 9:
        exception = RuntimeError('Something went wrong')
 
    user.environment.events.request.fire(
        request_type=f'lm.generate',
        name=model,
        response_time=elapsed_time,
        response_length=output_tokens,
        exception=exception 
    )

class SaxmlUser(User):
    """
    A class simulating calls to Saxml model servers.
    """

    def __init__(self, environment):
        super().__init__(environment)

    
    wait_time = between(1, 1)

    def on_start(self):
        
        self.tasks.clear()
        task = partial(lm_generate_task,
                       model='llama7b')
        update_wrapper(task, lm_generate_task) 

        self.tasks.append(task)

    def on_stop(self):
        self.tasks.clear()

