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
import sax

from typing import Union

from fastapi import FastAPI

# Temporary hack for experimentation
_model_id = os.getenv('MODEL_ID', '/sax/test/llama7bfp16tpuv5e')
_model = sax.Model(_model_id)
_lm = _model.LM()


app = FastAPI()

@app.get("/")
def read_root():
    return {"Hello": "World"}


@app.get("/generate")
def lm_generate():
    prompt = "Who are you?"

    #generate_response = _lm.Generate(prompt)

    #response = {
    #    'generate_response': generate_response[0][0] 
    #} 
    response = "I am the greatest"
    return response

