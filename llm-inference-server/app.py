from fastapi import FastAPI
from fastapi.responses import JSONResponse
import uvicorn
from mangum import Mangum
from dotenv import load_dotenv
import os
from llama_index.llms.llama_api import LlamaAPI
from llama_index.core.base.llms.types import ChatMessage, MessageRole
import requests
import json

# Initialise the server
app = FastAPI()
handler = Mangum(app)

# Initialise the LLM (Llama 3.1-405B)
load_dotenv()
api_key = os.getenv("LLAMA_API_KEY")
llm = LlamaAPI(api_key=api_key, model="llama3.1-405b")


@app.get('/get_response')
def get_response(user_id: int):
    # Request the user's message history
    response = requests.get(f'https://szhp6s7oqx7vr6aspphi6ugyh40fhkne.lambda-url.eu-north-1.on.aws/get_messages?user_id={user_id}')
    data = json.loads(response.content)["data"]

    # Convert the message history to the format Llama API can understand
    messages = []
    for message in data:
        role = ""
        if message[2] == 1:
            role = MessageRole.USER
        elif message[2] == 2:
            role = MessageRole.ASSISTANT
        messages.append(ChatMessage(content=message[1], role=role))
    
    # Call the LLM
    response = str(llm.chat(messages=messages).message.content)

    return JSONResponse({"response": response})


if __name__ == "__main__":
    # Run the server
    uvicorn.run(app, host="127.0.0.1", port=8001, log_config="log.ini")