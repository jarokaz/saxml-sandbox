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
from locust import events
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
    def __init__(self, env: Environment, project_id: str, topic_name: str, minimum_message_queue_length: int = 10, maximum_message_queue_length: int = 500, publisher_sleep_time: int = 1):
        self.topic_path = f"projects/{project_id}/topics/{topic_name}"
        self.client = PublisherClient()
        self.messages = []
        self.minimum_message_queue_length = minimum_message_queue_length
        self.maximum_message_queue_length = maximum_message_queue_length
        self.publisher_sleep_time = publisher_sleep_time
        self.request_handler = None
        self.test_id = None
        self.environment = env
        env.events.test_start.add_listener(self.on_test_start)

    def on_test_start(self, environment, **kwargs):
        """Registers the request handler and starts the publishing greenlet."""

        self.test_id = None
        if not isinstance(environment.runner, MasterRunner):
            # Remove any previously registered request handler
            if self.request_handler:
                environment.events.request.remove_listener(
                    self.request_handler)
                self.request_handler = None

            if environment.parsed_options.metrics_tracking == "enabled":
                if environment.parsed_options.test_id:
                    self.test_id = environment.parsed_options.test_id
                    logging.info("Adding request listener")
                    self.request_handler = environment.events.request.add_listener(
                        self.log_request)
                    logging.info("Spawning a publishing greenlet")
                    gevent.spawn(self.publisher, self.publisher_sleep_time).link_exception(
                        greenlet_exception_handler())
                else:
                    logging.warning(
                        "Test ID not set. Metrics tracking disabled.")
            else:
                logging.info("Metrics tracking disabled by a user")

    def publisher(self, sleep_time=1):
        """This function is executed by a publishing greenlet

           It awakens every configured seconds and publishes 
           accumulated metrics to a configured Pubsub topic.
        """
        logging.info("Entering the Pubsub publishing greenlet")
        logging.info("Waiting for the runner to start")
        while self.environment.runner.state != STATE_RUNNING:
            gevent.sleep(1)
            continue
        logging.info("The runner has starterd.")
        while self.environment.runner.state == STATE_RUNNING:
            gevent.sleep(sleep_time)
            self.publish_messages()
        logging.info("The runner has stopped.")
        self.publish_messages()
        logging.info("Exiting the Pubsub publishing greenlet.")

    def publish_messages(self):
        """Publishes all metrics messages in a message queue."""

        if len(self.messages) >= self.minimum_message_queue_length:
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
        """This is an event handler for Locust on_request events.
           It prepares a metric proto buffer and appends it to a message queue.
        """

        print("***************")
        print("In log_request")
        print(f"Exception: {exception}")
        print(f"Response: {response}")
        print(f"Contenxt: {context}")
        return

        if not self.test_id:
            logging.warning(
                "Test ID NOT configured. The message will not be tracked.")
            return

        if len(self.messages) > self.maximum_message_queue_length:
            logging.warning(
                f"Maximum number of request records queued - {len(self.messages)}. Removing the oldest record")
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
        """Prepare a metrics protobuf."""

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
        if context.get("prompt_parameters"):
            metrics.prompt_parameters = context["prompt_parameters"]
        if context.get("completions"):
            metrics.completion = context["completions"]
        metrics = json.dumps(MessageToDict(metrics)).encode("utf-8")
        message = PubsubMessage(data=metrics)

        return message


@events.init_command_line_parser.add_listener
def _(parser):
    parser.add_argument("--metrics_tracking", include_in_web_ui=True, choices=["enabled", "disabled"], default="enabled",
                        help="Whether to publish metrics to Pubsub topic")
    parser.add_argument("--query_response_logging", include_in_web_ui=True, choices=["enabled", "disabled"], default="enabled",
                        help="Whether to include request and response content in published metrics")
    parser.add_argument("--test_id", type=str,
                        include_in_web_ui=True, default="", help="Test ID")
    parser.add_argument("--topic_name", type=str, env_var="TOPIC_NAME",
                        include_in_web_ui=False, default="locust_pubsub_sink",  help="Pubsub topic name")
    parser.add_argument("--project_id", type=str, env_var="PROJECT_ID",
                        include_in_web_ui=False, default="jk-mlops-dev",  help="Project ID")
    parser.add_argument("--maximum_message_queue_length", type=int, env_var="MAXIMUM_MESSAGE_QUEUE_LENGTH",
                        include_in_web_ui=False, default=1000, help="The maximum size of the in-memory message queue that stages messages for publishing")
    parser.add_argument("--minimum_message_queue_length", type=int, env_var="MINIMUM_MESSAGE_QUEUE_LENGTH",
                        include_in_web_ui=False, default=10, help="The batch of messages will be published after the length of the in-memory message queue goes over this threshold")


def config_metrics_tracking(environment: Environment):
    if environment.parsed_options.topic_name and environment.parsed_options.project_id:
        logging.info(
            f"Registering Pubsub publisher for topic {environment.parsed_options.topic_name}")
        PubsubAdapter(env=environment, project_id=environment.parsed_options.project_id, topic_name=environment.parsed_options.topic_name,
                      minimum_message_queue_length=environment.parsed_options.minimum_message_queue_length, maximum_message_queue_length=environment.parsed_options.maximum_message_queue_length)

    else:
        logging.warning(
            'No Pubsub topic configured. Metrics will not be tracked. To enable tracking you must set --topic_name and --project_id parameters.')
