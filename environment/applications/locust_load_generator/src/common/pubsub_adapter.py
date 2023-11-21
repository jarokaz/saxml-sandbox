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
import time
from datetime import datetime
import gevent
import grpc.experimental.gevent as grpc_gevent

from google.cloud import pubsub_v1
from google.protobuf.json_format import MessageToDict
from google.pubsub_v1.services.publisher.client import PublisherClient
from google.pubsub_v1.types import PubsubMessage

from locust.env import Environment
from locust.runners import STATE_STOPPING, STATE_STOPPED, STATE_CLEANUP, STATE_RUNNING, MasterRunner

from common import metrics_pb2

# patch grpc so that it uses gevent instead of asyncio
grpc_gevent.init_gevent()

def greenlet_exception_handler():
    """
    Returns a function that can be used as an argument to Greenlet.link_exception() to capture
    unhandled exceptions.
    """
    def exception_handler(greenlet):
        logging.error("Unhandled exception in greenlet: %s", greenlet,
                      exc_info=greenlet.exc_info)
        global unhandled_greenlet_exception
        unhandled_greenlet_exception = True
    return exception_handler


class PubsubAdapter:
    def __init__(self, environment: Environment, topic_path: str, batch_size=10, maximum_batch_size=500):
        self.environment = environment
        self.topic_path = topic_path
        self.client = PublisherClient()
        self.messages = []
        self.batch_size = batch_size
        self.maximum_batch_size = maximum_batch_size

        if not isinstance(environment.runner, MasterRunner):
            self.environment.events.request.add_listener(self.log_request)
            self.environment.events.test_stop.add_listener(self.on_test_stop)
            self.environment.events.test_start.add_listener(self.on_test_start)


    def flusher(self):
        logging.info("Entering the Pubsub publishing greenlet")
        logging.info("Waiting for the runner to start")
        while self.environment.runner.state != STATE_RUNNING:
            gevent.sleep(1)
            continue
        logging.info("The runner has starterd.")
        while self.environment.runner.state == STATE_RUNNING:
#        while not self.environment.runner.state in [STATE_STOPPING, STATE_STOPPED, STATE_CLEANUP]:
            gevent.sleep(1)
            self.flush_messages()
        logging.info("The runner has stopped.")
        logging.info("Exiting the Pubsub publishing greenlet.")


    def flush_messages(self, force: bool=False):

        if self.messages:
            if force or (len(self.messages) >= self.batch_size):
                try:
 
                    start_time = time.time()
                    self.client.publish(topic=self.topic_path,
                                        messages=self.messages)
                    total_time = int((time.time() - start_time) * 1000)
                    logging.info(
                        f"Published {len(self.messages)} request records to {self.topic_path} in {total_time} miliseconds")
                    self.messages = []
                except Exception as e:
                    logging.error(
                        f"Exception when publishing request records - {e}")

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

        if not self.test_id:
            logging.warning(
                "Test ID NOT configured. The message will not be tracked.")
            return

        if len(self.messages) > self.maximum_batch_size:
            logging.warning(
                f"Maximum number of request records reached - {len(self.messages)}. Removing the oldest record")
            self.messages.pop()

        message = self._prepare_message(
            test_id=self.test_id,
            request_type=request_type,
            name=name,
            response_time=response_time,
            response_length=response_length,
            response=response,
            context=context,
            exception=exception,
            start_time=start_time)

        self.messages.append(message)

    def _prepare_message(self,
                         test_id: str,
                         request_type: str,
                         name: str,
                         response_time: int,
                         response_length: int,
                         response: object,
                         context: dict,
                         exception: Exception,
                         start_time: datetime):

        metrics = metrics_pb2.Metrics()
        metrics.test_id = test_id
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
        if context.get("model_server_response_time"):
            metrics.model_server_response_time = context["model_server_response_time"]
        if context.get("prompt"):
            metrics.prompt = context["prompt"]
        if context.get("completion"):
            metrics.completion = context["completion"]
        metrics = json.dumps(MessageToDict(metrics)).encode("utf-8")
        message = PubsubMessage(data=metrics)

        return message


    def on_test_stop(self, environment: Environment, **kwargs):

        logging.info(
            f"Flushing the remaining messages as test {self.test_id} is stopping")
        self.flush_messages(force=True)

    def on_test_start(self, environment: Environment, **kwargs):
         
        if environment.parsed_options.test_id:
            self.test_id = environment.parsed_options.test_id
            logging.info(
                f"Pubsub adapter configured for test {self.test_id}")
        else:
            self.test_id = None
            logging.warning(
                f"Test ID not configured. Pubsub adapter tracking disabled."
            )
        self.batch_size = environment.parsed_options.message_buffer_size
        self.messages = []
        gevent.spawn(self.flusher).link_exception(greenlet_exception_handler())
        logging.info("Spawned Pubsub publishing greenlet")
