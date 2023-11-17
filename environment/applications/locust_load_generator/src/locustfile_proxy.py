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
import logging
import random
import time
from datetime import datetime

import grpc.experimental.gevent as grpc_gevent

import jsonlines

from google.cloud import pubsub_v1
from locust import  task, between, HttpUser, env, events
from google.pubsub_v1.services.publisher.client import PublisherClient

# patch grpc so that it uses gevent instead of asyncio
grpc_gevent.init_gevent()

class PubSubListener:
    def __init__(self, environment: env.Environment, topic_path: str, batch_size=2, maximum_batch_size=500):
        self.environment = environment
        self.topic_path = topic_path
        self.logger = logging.getLogger(__name__)
        self.client = PublisherClient()
        self.messages = []
        self.batch_size = batch_size
        self.maximum_batch_size = maximum_batch_size
        self.environment.events.request.add_listener(self.log_request)
        self.counter = 0
        
    def log_request(self, 
                    request_type: str, 
                    name: str,
                    response_time: int, 
                    response_length: int, 
                    response: object, 
                    context: dict, 
                    exception: Exception, 
                    start_time: datetime, 
                    **kwargs):

        self.counter += 1
        data = {
            'request_type': 'lm.generate',
            'response_lengt': 100
        }

        message_data = bytes(json.dumps(data).encode(encoding='utf-8'))
        message = {
            'data': message_data,
            'attributes': {
                'message_number': str(self.counter)
            }
        }
        
        if len(self.messages) > self.maximum_batch_size:
            logging.warning(f"Maximum number of request records reached - {len(self.messages)}. Removing the oldest record")
            self.messages.pop()

        self.messages.append(message)

        if len(self.messages) > self.batch_size:
            try:
                logging.info(f"Publishing {len(self.messages)} request records to {self.topic_path}")
                self.client.publish(topic=self.topic_path, messages=self.messages) 
                self.messages = []
            except Exception as e:
                logging.error(f"Exception when publishing request records - {e}")




class SaxmlUser(HttpUser):
    wait_time = between(2, 2)
    @task
    def smoke_test(self):
        self.client.get("/generate")



@events.init.add_listener
def on_locust_init(environment, **kwargs):
    PubSubListener(environment=environment,
                   topic_path='projects/jk-mlops-dev/topics/locust_pubsub_sink')