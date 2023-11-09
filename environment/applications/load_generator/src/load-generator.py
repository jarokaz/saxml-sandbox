#import tensorflow as tf
import os, sys
import numpy as np
import threading
import multiprocessing as mp
import time
import argparse
import json
import jsonlines

from transformers import LlamaTokenizer
import huggingface_hub
import sax

import pprint

pp = pprint.PrettyPrinter(indent=4)
 


def register_sax_model(model_id):
  model = sax.Model(model_id)
  global lm_model
  lm_model = model.LM()

def process_data(batch):
  option = sax.ModelOptions()
  option.SetExtraInput("per_example_max_decode_steps", 128)
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
  parser = argparse.ArgumentParser()
  parser.add_argument('-m', '--model', type=str)
  parser.add_argument('-d', '--data', type=str)
  parser.add_argument('-o', '--output', type=str) 
  parser.add_argument('-t', '--test_id', type=str)
  parser.add_argument('-n', '--num_batches', type=int, default=32)
  parser.add_argument('-b', '--batch_size', type=int, default=1)
  parser.add_argument('-t', '--num_threads', type=int, default=1)
  args = parser.parse_args()

  register_sax_model(args.model)
  prompts = create_prompt_data(args.data)
  num_prompts = args.num_batches * args.batch_size
  prompts = prompts[:num_prompts]

  start = time.time()
  batched_data = []
  for i in range(0, args.num_batches):
    batched_data.append(prompts[i:i+args.batch_size])

  total_input_tokens = 0
  total_output_tokens = 0

  print('Starting the test ...')
  with mp.pool.ThreadPool(processes=args.num_threads) as pool:
    for result in pool.map(process_data, batched_data):
      total_input_tokens += result[0]
      total_output_tokens += result[1]

  total_time = time.time() - start
  
  test_results = {}
  test_results['batch_size'] = args.batch_size
  test_results['threads'] = args.num_threads
  test_results['prompts'] = len(prompts) 
  test_results['batches'] = len(batched_data) 
  test_results['input_tokens'] = total_input_tokens
  test_results['output_tokens'] = total_output_tokens 
  test_results['time'] = total_time 
  test_results['time_per_batch'] = total_time / len(batched_data)
  test_results['time_per_input'] = total_time / len(prompts 
  test_results['time_per_output_token'] = total_time / total_output_tokens
  test_results['output_tokens_per_second'] = total_output_tokens / total_time
  test_results['input_tokens_per_prompt'] = total_input_tokens / len(prompts)
  test_results['output_tokens_per_prompt'] = total_output_tokens / len(prompts)
  test_results['prompts'] = len(prompts) 
  test_results['prompts'] = len(prompts) 
  test_results['prompts'] = len(prompts) 
  print('Test completed ...')
  pp.pprint(test_results)  

  test_results_file_path = os.path.join(output, f'{test_id}.json')
  with open(test_results_file_path, 'w') as f:
    json.dump(test_results, f)


if __name__ == '__main__':
  HUGGINGFACE_TOKEN="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"
  huggingface_hub.login(token=HUGGINGFACE_TOKEN)
  tokenizer = LlamaTokenizer.from_pretrained("meta-llama/Llama-2-7b-hf") 
  main()

