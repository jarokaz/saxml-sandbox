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

from pydantic import BaseModel


class ModelOptions

class Prompt(BaseModel):
    prompt: str
    

# Temporary hack for experimentation
_model_id = os.getenv('MODEL_ID', '/sax/test/llama7bfp16tpuv5e')
_model = sax.Model(_model_id)
_lm = _model.LM()

app = FastAPI()

@app.get("/")
def read_root():
    return {"Hello": "World"}


@app.post("/generate", status_code=status.HTTP_200_OK)
def lm_generate(prompt: Prompt):

    try:
        start_time = time.time()
        completions = _lm.Generate(prompt.prompt) 
        total_time = int((time.time() - start_time) * 1000)
        response = {
            "response": completions,
            "performance_metrics": {
                "response_time": total_time 
        }
    }
    except Exception as e:
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="Exception in Saxml client") 

    return response




