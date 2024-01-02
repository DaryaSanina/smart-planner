import os
import argparse
from dotenv import load_dotenv
import pandas as pd
from openai import OpenAI

load_dotenv()  # Load environment variables
openai_api_key = os.getenv('OPENAI_API_KEY')  # Load OpenAI API key

parser = argparse.ArgumentParser()  # Create a parser

# Add arguments to the parser
parser.add_argument("n_examples")
parser.add_argument("filename")
args = parser.parse_args()

openai_client = OpenAI(api_key=openai_api_key)  # Create an OpenAI client
model = "gpt-3.5-turbo"

examples_to_generate = int(args.n_examples)
data = set()

while examples_to_generate > 0:
    messages = [
        {
            "role": "system",
            "content": "You are a machine learning dataset generator. You generate datasets the user asks you to generate in the format they specify."
        },
        {
            "role": "user",
            "content": f"Generate a dataset of {examples_to_generate} examples where features are task names a user might input in a daily planner and targets are corresponding levels of importance from 1 to 10 the user might give to the task (1 is not important, 10 is very important) and the time the task might take to complete in minutes. The tasks should represent a variety of different types of users. The task name can include an importance estimation described in words. Generate the dataset in the following format: <index>. <task name> - <task importance> - <time to complete the task>."
        }
    ]

    completion = openai_client.chat.completions.create(model=model, messages=messages)  # Make a prompt to GPT to generate the dataset
    response = completion.choices[0].message.content.split('\n')  # Extract the response as a list of examples as strings in the following format: <task name> - <task importance>

    for example in response:
        try:
            task = example.split('. ')[1].split(' - ')[0]
            importance = int(example.split(' - ')[1])
            time = int(example.split(' - ')[2])
            data.add((task, importance, time))  # Add the example to the list of examples to be saved
        except Exception as e:  # If the task is not in the specified format
            pass
    examples_to_generate = int(args.n_examples) - len(data)

dataframe = pd.DataFrame(data=list(data), columns=["Task", "Importance", "Time to complete (minutes)"])  # Create a Pandas dataframe with the generated examples
dataframe.to_csv(args.filename)  # Append the dataframe to the dataset
