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
model = "gpt-4-turbo-preview"

examples_to_generate = int(args.n_examples)
data = set()

while examples_to_generate > 0:
    messages = [
        {
            "role": "system",
            "content": "You are designed to assist with generating datasets for Machine Learning. " +
            "You aim to ensure the datasets are optimized for training models to achieve top performance. " +
            "This involves suggesting data preprocessing techniques, identifying potential data sources, " +
            "and advising on data augmentation strategies to enhance model accuracy and generalizability. " +
            "You will focus on maintaining data integrity, ensuring diversity and balance in the datasets, and complying with data privacy laws. " +
            "You will also provide insights into feature engineering and selection to improve model outcomes."
        },
        {
            "role": "user",
            "content": f"Generate a dataset of {examples_to_generate} examples to train an LSTM to identify the importance of a task in a daily planner. Each record should contain:\n" +
                        "1. The name of the task - a string of no more than 30 characters. It should be similar to how a real person would name a task in a daily planner.\n" +
                        "2. The description of the task - several sentences describing the task and whether it is important for the user or not.\n" +
                        "3. The importance of the task - a number from 0 to 10, where 0 is not important and 10 is very important.\n" +
                        "Provide only the dataset itself without any comments or notes in the following format. 3 lines for each record (name, description, importance), a single empty line between any two records. " +
                        "Remember, do not output ANYTHING other than the dataset itself (meaning no introduction and no conclusion, JUST a list of records), your response will be processed automatically."
        }
    ]

    completion = openai_client.chat.completions.create(model=model, messages=messages)  # Make a prompt to GPT to generate the dataset
    try:
        response = completion.choices[0].message.content.split('\n')  # Extract the response as a list of examples as strings in the following format: <task name> - <task importance>
    except Exception as e:
        print(e)
        continue

    for i in range(0, len(response), 4):
        try:
            name = response[i]
            description = response[i + 1]
            importance = int(response[i + 2])
            data.add((name, description, importance))  # Add the example to the list of examples to be saved
        except Exception as e:  # If the task is not in the specified format
            pass
    examples_to_generate = int(args.n_examples) - len(data)

dataframe = pd.DataFrame(data=list(data), columns=["Name", "Description", "Importance"])  # Create a Pandas dataframe with the generated examples
dataframe.to_csv(args.filename)  # Append the dataframe to the dataset
