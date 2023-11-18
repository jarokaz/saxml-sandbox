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
from locust import task, between, HttpUser, env, events
from google.protobuf.json_format import MessageToDict
from google.pubsub_v1.services.publisher.client import PublisherClient
from google.pubsub_v1.types import PubsubMessage

import metrics_pb2

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

    def _prepare_message(self,
                         request_type: str,
                         name: str,
                         response_time: int,
                         response_length: int,
                         response: object,
                         context: dict,
                         exception: Exception,
                         start_time: datetime):

        metrics = metrics_pb2.Metrics()
        metrics.test_id = context["test_id"]
        metrics.request_type = request_type
        metrics.request_name = name
        metrics.response_time = response_time
        metrics.response_length = response_length
        metrics.start_time = time.strftime(
            "%Y-%m-%d %H:%M:%S",  time.localtime(start_time))
        if context.get("num_output_tokens"):
            metrics.num_output_tokens = context["num_output_tokens"]
        if context.get("num_input_tokens"):
            metrics.num_input_tokens = context["num_input_tokens"]
        if context.get("model_name"):
            metrics.model_name = context["model_name"]
        if context.get("model_method"):
            metrics.model_method = context["model_method"]
        metrics = json.dumps(MessageToDict(metrics)).encode("utf-8")
        message = PubsubMessage(data=metrics)

        return message

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

        if len(self.messages) > self.maximum_batch_size:
            logging.warning(
                f"Maximum number of request records reached - {len(self.messages)}. Removing the oldest record")
            self.messages.pop()

        message = self._prepare_message(
            request_type=request_type,
            name=name,
            response_time=response_time,
            response_length=response_length,
            response=response,
            context=context,
            exception=exception,
            start_time=start_time)

        self.messages.append(message)

        if len(self.messages) > self.batch_size:
            try:
                logging.info(
                    f"Publishing {len(self.messages)} request records to {self.topic_path}")
                self.client.publish(topic=self.topic_path,
                                    messages=self.messages)
                self.messages = []
            except Exception as e:
                logging.error(
                    f"Exception when publishing request records - {e}")


class SaxmlUser(HttpUser):
    wait_time = between(5, 5)

    @task
    def smoke_test(self):

        with self.client.get("/generate", catch_response=True) as resp:
            resp.request_meta["context"]["test_id"] = test_id
            resp.request_meta["context"]["num_output_tokens"] = 100
            resp.request_meta["context"]["model_name"] = model_id
            resp.request_meta["context"]["model_method"] = "lm.Generate"
            resp.request_meta["context"]["num_input_tokens"] = 200


@events.init.add_listener
def on_locust_init(environment, **kwargs):
    PubSubListener(environment=environment,
                   topic_path='projects/jk-mlops-dev/topics/locust_pubsub_sink')

@events.test_start.add_listener
def _(environment, **kwargs):
    global test_id
    global model_id

    test_id = environment.parsed_options.test_id
    model_id = environment.parsed_options.model_id 
    print("Starting test")
    print(environment.parsed_options.test_id)
    print(environment.parsed_options.model_id)



@events.test_stop.add_listener
def _(environment, **kwargs):
    print("Stopping test")


@events.init_command_line_parser.add_listener
def _(parser):
    parser.add_argument("--test_id", type=str, env_var="TEST_ID", include_in_web_ui=True, default="", help="Test ID")
    parser.add_argument("--model_id", type=str, env_var="MODEL_ID", include_in_web_ui=True, default="", help="Model ID")