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
import logging
import sax
import time

from typing import Union
from fastapi import FastAPI, HTTPException, status

from typing import Optional
from pydantic import BaseModel


class ModelOptions(BaseModel):
    temperature: Optional[float] = None
    top_k: Optional[int] = None
    top_p: Optional[float] = None
    per_example_max_decode_steps: Optional[int] = None


class Query(BaseModel):
    prompt: str
    model_id: str
#    model_options: ModelOptions


class TestThroughputParams(BaseModel):
    delay: int = 100

# Temporary hack for experimentation

_model_id = os.getenv('MODEL_ID', '/sax/test/llama7bfp16tpuv5e')
_model = sax.Model(_model_id)
_lm = _model.LM()

_lm_models = {
    _model_id: _lm
}

app = FastAPI()


@app.get("/")
def read_root():
    return {"Hello": "World"}
    
@app.post("/test_througput")
def test_throughput(test_params: TestThroughputParams):
    logging.info(f"Going to sleep for {test_params.delay} seconds")
    time.sleep(test_params.delay)

    return {"Response": "Whatever"}


@app.post("/generate", status_code=status.HTTP_200_OK)
def lm_generate(query: Query):

    try:
        lm = _lm_models.get(query.model_id)
        if not lm:
            raise RuntimeError(f"Unsupported model: {query.model_id}")
        start_time = time.time()
        completions = _lm.Generate(query.prompt)
        total_time = int((time.time() - start_time) * 1000)
        response = {
            "response": completions,
            "performance_metrics": {
                "response_time": total_time
            }
        }
    except Exception as e:
        print(e)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=f"Exception in Saxml client: {e}")

    return response
