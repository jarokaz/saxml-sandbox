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

import argparse
import datetime
import os
import pprint
import json
import time

import huggingface_hub
import jsonlines
import sax

from functools import partial
from multiprocessing.pool import ThreadPool
from transformers import LlamaTokenizer

pp = pprint.PrettyPrinter(indent=4)


def register_sax_model(model_id):
    model = sax.Model(model_id)
    global lm_model
    lm_model = model.LM()


def process_batch(batch, lm_model, tokenizer, per_example_max_decode_steps):
    option = sax.ModelOptions()
    option.SetExtraInput("per_example_max_decode_steps",
                         per_example_max_decode_steps)
    num_prompt_tokens = 0
    num_output_tokens = 0
    for prompt in batch:
        num_prompt_tokens += len(tokenizer.encode(prompt))
        predicted = lm_model.Generate(prompt, option)
        num_output_tokens += len(tokenizer.encode(predicted[0][0]))
    return num_prompt_tokens, num_output_tokens,


def create_prompt_data(filename):
    prompts = []
    with jsonlines.open(filename) as reader:
        for obj in reader:
            prompts.append(obj['input'])

    return prompts


def main():

    #register_sax_model(args.model)
    prompts = create_prompt_data(args.data)
    num_prompts = args.num_batches * args.batch_size
    prompts = prompts[:num_prompts]

    batched_data = []
    for i in range(0, args.num_batches):
        batched_data.append(prompts[i:i+args.batch_size])

    total_input_tokens = 0
    total_output_tokens = 0

    huggingface_hub.login(token=os.environ['HUGGINGFACE_TOKEN'])
    tokenizer = LlamaTokenizer.from_pretrained(args.tokenizer)
    model = sax.Model(args.model_id)
    lm_model = model.LM()

    process_batch_p = partial(process_batch,
                              lm_model=lm_model,
                              tokenizer=tokenizer,
                              per_example_max_decode_steps=args.per_example_max_decode_steps)

    start_datetime = datetime.datetime.now()
    test_id = f'{args.test_id}-{start_datetime.strftime("%Y-%m-%d-%H-%M-%S")}'
    print(f'Starting the test: {test_id} ...')
    start = time.time()

    with ThreadPool(processes=args.num_threads) as pool:
        for result in pool.map(process_batch_p, batched_data):
            total_input_tokens += result[0]
            total_output_tokens += result[1]

    total_time = time.time() - start

    test_results = {
        'test_configuration': {
            'test_id': test_id,
            'tpu_type': args.tpu_type,
            'tpu_topology': args.tpu_topology,
            'model_id': args.model_id,
            'tokenizer': args.tokenizer,
            'batch_size': args.batch_size,
            'num_threads': args.num_threads,
            'num_batches': args.num_batches,
            'per_example_max_decode_steps': args.per_example_max_decode_steps,
        },
        'test_results': {
            'num_processed_prompts': len(prompts),
            'num_processed_batches': len(batched_data),
            'input_tokens':  total_input_tokens,
            'output_tokens': total_output_tokens,
            'time': total_time,
            'time_per_batch': total_time / len(batched_data),
            'time_per_input': total_time / len(prompts),
            'time_per_output_token': total_time / total_output_tokens,
            'output_tokens_per_second': total_output_tokens / total_time,
            'input_tokens_per_prompt': total_input_tokens / len(prompts),
            'output_tokens_per_prompt': total_output_tokens / len(prompts),
        }
    }
    print('Test completed ...')
    pp.pprint(test_results)

    os.makedirs(args.output, exist_ok=True)
    test_results_file_path = os.path.join(args.output, f'{test_id}.json')
    with open(test_results_file_path, 'w') as f:
        json.dump(test_results, f)


### Define flags ###
parser = argparse.ArgumentParser()
parser.add_argument('--model_id', type=str, default='/sax/test/llama7bfp16tpuv5e')
parser.add_argument('--tokenizer', type=str,
                    default='meta-llama/Llama-2-7b-hf')
parser.add_argument('--tpu_type', type=str, default='tpu-v4-podslice')
parser.add_argument('--tpu_topology', type=str, default='2x2x1')
parser.add_argument('--data', type=str,
                    default='orca_prompts.jsonl')
parser.add_argument('--output', type=str,
                    default='/model_repository/benchmarking/test_runs')
parser.add_argument('--test_id', type=str, default='test1111')
parser.add_argument('--num_batches', type=int, default=32)
parser.add_argument('--batch_size', type=int, default=1)
parser.add_argument('--num_threads', type=int, default=1)
parser.add_argument('--per_example_max_decode_steps', type=int, default=128)
args = parser.parse_args()

if __name__ == '__main__':
    main()
