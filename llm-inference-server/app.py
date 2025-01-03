from fastapi import FastAPI
from fastapi.responses import JSONResponse
import uvicorn
from mangum import Mangum
from dotenv import load_dotenv
import os
from llama_index.llms.llama_api import LlamaAPI
from llama_index.core.base.llms.types import ChatMessage, MessageRole
from llama_index.core.constants import DEFAULT_NUM_OUTPUTS
from pydantic import BaseModel, Field
import requests
import json
from enum import Enum
import datetime

ASSISTANT_SYSTEM_PROMPT = """
You are an expert in task management. You assist the user in managing their tasks. You are friendly and welcoming and eager
to help the user complete their tasks.

You can receive queries from the user as well as some relevant information about their tasks. This information will be in
the form of a JSON string which consists of a list of tasks. This list only consists of the tasks relevant to the problem,
and as such may not contain all of the user's tasks, or may even be empty, if no tasks are relevant to the user's problem.
Each task will have a name, a description, some time constraints (either a deadline or a start date-time and an end
date-time), and an importance level from 1 to 10. A task may also have some of the following reminders: 10 minutes before,
1 hour before, 1 day before and 1 week before. A task can also have a list of tags it is associated with. When the user
asks you to mark a task as complete, it means they want you to remove the task from the list.
You can use this data to fulfill the user's queries.

You should keep your responses short.
"""

sql_generator_system_prompt = f"""
Please take into account all of the previous instructions.

You are an expert in writing SQL queries to retrieve data that might be helpful to solve the user's problems. The problems
are based around task management.

You have a database of the user's tasks. The database contains the following tables:
1. Tasks - the user's tasks.
2. Tags - the tags the user can assign to tags.
3. TasksToTags - each record indicates that a specified tag has been assigned to a specified task. It is a many-to-many
relationship.
4. Reminders - each record indicates that a specified task has a specified reminder. A task can have many reminders.

The Tasks table contains the following fields:
1. TaskID - INT PRIMARY KEY AUTO_INCREMENT NOT NULL - a unique identifier of the task.
2. Name - VARCHAR(50) NOT NULL - the name or title of the task.
3. Description - TEXT - a long description of the task with detailed notes about it.
4. Deadline - DATETIME - the deadline by which the task needs to be completed.
5. Start - DATETIME - if the task does not have a deadline, it needs to have a start and an end (in this case it is treated
more like an event).
6. End - DATETIME - see above.
7. Importance - INT NOT NULL - the task's level of importance (an integer from 1 to 10).

The Tags table contains the following fields:
1. TagID - INT PRIMARY KEY AUTO_INCREMENT NOT NULL - a unique identifier of the tag.
2. Name - VARCHAR(32) NOT NULL - the tag's label.

The TasksToTags table contains the following fields:
1. TaskToTagID - INT PRIMARY KEY AUTO_INCREMENT - a unique ID of the relationship between the task and the tag.
2. TaskID - INT NOT NULL FOREIGN KEY - the ID of the task that needs to be associated with the tag.
3. TagID - INT NOT NULL FOREIGN KEY - the ID of the tag the task needs to be associated with.

The Reminders table contains the following fields:
1. ReminderID - INT PRIMARY KEY AUTO_INCREMENT NOT NULL - a unique identifier of the record.
2. TaskID - INT NOT NULL FOREIGN KEY - the ID of the task with the reminder specified in this record.
3. ReminderType - INT NOT NULL - the type code for the reminder. 1 means 10 minutes before, 2 means 1 hour before,
3 means 1 day before, and 4 means 1 week before. If the task has a start and an end instead of a deadline, the reminder
will go off the specified amount of time before the start of the task.

Here is the userID you should use: USER_ID
If needed, you can also use the following information:
Today is CURRENT_DATE
The current time is CURRENT_TIME_HOUR:CURRENT_TIME_MINUTE

You will be given the conversation between the user and another assistant and you will need to decide whether the last query
of the user needs data from the database to be fulfilled or if it can be fulfilled more efficiently with the data from the
database and write an SQL query to get that data. You can also decide that no data from the database is needed.

You will need to output a JSON object with a text explanation of the SQL query and the query itself.
The JSON object should have the following format:
{{
    "reasoning": The reasoning about what data needs to be retrieved and what SQL command might retrieve the data or at
                 least narrow down the scope of the data. You can also decide that you don't need any data at all.
                 This should be in double quotation marks.
    "sql_query": The SQL query to retrieve the necessary data. If no data needs to be retrieved, leave it blank.
                 This should be in double quotation marks.
}}

Do not output anything else under any circumstances.
"""

action_generator_system_prompt = f"""
You are an expert in task management and planning. Based on the conversation history with the user, you will need to determine whether
you need to create a task, edit a task, mark a task as done, or do nothing, and output the details of the action.

If no action needs to be done, output "Nothing". This should be done in most cases unless specifically stated by the user.

If a task needs to be created, the output should have the following format (each thing on one separate line):
"Create"
"Name: " task name
"Description: " task description
"Importance: " task importance (an integer from 0 to 10, 0 is the lowest importance, 10 is the highest importance)
"Deadline: " / "Start: " either the task's deadline or its start datetime
(Optional) "End: " the task's end datetime (if it has a start and an end instead of a deadline)

If a task needs to be edited, the output should have the following format (each thing on one separate line):
"Edit"
"Id: " task id (you will have the information about the task id in the message history)
<field name>: new value (this line can be repeated multiple times, if multiple fields need to be updated)

If a task needs to be marked as done, the output should have the following format (each thing on one separate line):
"Complete"
"Id: " task id

All dates should be in one of the following formats: "YYYY-MM-DD" or "YYYY-MM-DD[T]HH:MM"

If needed, you can also use the following information:
Today is CURRENT_DATE
The current time is CURRENT_TIME_HOUR:CURRENT_TIME_MINUTE

Do not output anything else under any circumstances.
"""


class ActionType(str, Enum):
    CREATE = "CREATE"
    EDIT = "EDIT"
    COMPLETE = "COMPLETE"
    ERROR = "ERROR"
    NOTHING = "NOTHING"


# Initialise the server
app = FastAPI()
handler = Mangum(app)

# Initialise the LLM (Llama 3.1-405B)
load_dotenv()
DEFAULT_NUM_OUTPUTS = 4096
assistant = LlamaAPI(api_key=os.getenv("LLAMA_API_KEY"), model="llama3.1-405b", max_tokens=4096)


class SQL_Output(BaseModel):
    """Output that contains an SQL query and the reasoning behind it.

    Parameters
    ----------
        reasoning : str
            The reasoning about what data needs to be retrieved and what SQL command might retrieve the data or at least
            narrow down the scope of the data. You can also decide that you don't need any data at all.
        
        sql_query : str
            The SQL query to retrieve the necessary data. If no data needs to be retrieved, leave it blank.
    """
    reasoning : str
    sql_query : str


def load_message_history(user_id: int, message_limit: int | None = None) -> list[ChatMessage]:
    """
    Requests the message history of the user with the given ID and returns it as a list of chat messages, including the
    user's messages, the assistant's messages, and the responses of any external tools, such as database queries, called
    by the assistant.

    Parameters
    ----------
    user_id : int
        The ID of the user to retrieve the message history from
    message_limit : int
        The maximum limit on the number of messages to be retrieved (starting from the latest message).
        If the limit is not specified, the whole message history will be retrieved.
    
    Returns
    -------
    list[ChatMessage]
        A list of chat messages that can be passed to an LLM to generate a response to the last message.
        Each message is marked with either a "user", an "assistant" or a "system" role.
    """

    # Request the user's message history
    response = requests.get(f'https://szhp6s7oqx7vr6aspphi6ugyh40fhkne.lambda-url.eu-north-1.on.aws/get_messages?user_id={user_id}')
    data = json.loads(response.content)["data"]

    # Convert the message history to the format Llama API can understand
    messages = []
    for message in data:
        role = ""
        if int(message[2]) == 1:
            role = MessageRole.USER
        elif int(message[2]) == 2:
            role = MessageRole.ASSISTANT
        messages.append(ChatMessage(content=message[1], role=role))
    
    if message_limit is None or message_limit > len(messages):
        return messages
    else:
        return messages[len(messages) - message_limit:]


def get_data(messages: list[ChatMessage], user_id: int, max_retries: int) -> ChatMessage:
    global sql_generator_system_prompt
    """
    In this function, an LLM analyses the last query of the user any previous conversation between the user and the assistant,
    decides which data it will need to perform the user's query and retrieves the data from the database server.

    Parameters
    ----------
    messages : list[ChatMessage]
        A conversation between the user and the assistant.
    max_retries : int
        The maximum number of times the LLM can repeat the data retrieval process, if there are any errors or the retrieved
        data is irrelevant to the query. If there are any such errors after the last attempt, the function will return
        a message without any data.
    
    Returns
    -------
    ChatMessage
        The content of the message is a JSON string with all the retrieved data stored as a list of database records with
        specified field names for each record. If the LLM decides that it doesn't need any data, or the maximum number of
        retries has been exceeded, the list will be empty.
        The role of this message is always MessageRole.TOOL.
    """
    try:
        # Generate an SQL query
        sql_generator = LlamaAPI(api_key=os.getenv("LLAMA_API_KEY"), model="llama3.1-405b", max_tokens=4096)
        sql_generator_system_prompt = sql_generator_system_prompt.replace("USER_ID", user_id)
        sql_generator_system_prompt = sql_generator_system_prompt.replace("CURRENT_DATE", datetime.date.today().strftime(format='%d %B %Y'))
        sql_generator_system_prompt = sql_generator_system_prompt.replace("CURRENT_TIME_HOUR", datetime.datetime.now().hour)
        sql_generator_system_prompt = sql_generator_system_prompt.replace("CURRENT_TIME_MINUTE", datetime.datetime.now().minute)
        output = sql_generator.chat(
            messages=[ChatMessage(content=sql_generator_system_prompt, role=MessageRole.SYSTEM)]
                + messages,
            max_tokens=4096
        )
        print(type(output), output)
        sql_query_object = json.loads(output.message.content)

        # Pass the SQL query to the database server
        database_response = requests.post(
            f'https://szhp6s7oqx7vr6aspphi6ugyh40fhkne.lambda-url.eu-north-1.on.aws/get_data_for_chatbot',
            json={"reasoning": sql_query_object["reasoning"], "sql_query": sql_query_object["sql_query"], "user_id": user_id},
            headers={'Content-Type': 'application/json'}
        )

        # If the database server has recognised the query as incorrect
        print(database_response.status_code)
        if database_response.status_code == 400:
            raise Exception(json.dumps(database_response.json()))
        
        # Retrieve the data and return it as a JSON string
        data = "Empty result"

        if database_response != "":
            data = database_response.json()["data"]
        print(data)
            
        assistant_response = ChatMessage(content=json.dumps(data), role=MessageRole.TOOL)

        return assistant_response

    except Exception as e:
        error_message = ChatMessage(content="Error: " + str(e), role=MessageRole.TOOL)
        if max_retries == 0:
            return error_message
        else:
            return get_data(messages, user_id, max_retries=max_retries - 1)


def parse_action(action_text: str) -> tuple[ActionType, dict]:
    lines = action_text.split('\n')
    task_details = dict(list(map(lambda x: tuple(x.lower().split(': ')), lines[1::])))

    if lines[0] == "Create":
        return (ActionType.CREATE, dict([(k.lower(), v) for k, v in task_details.items()]))
    elif lines[0] == "Edit":
        return (ActionType.EDIT, dict([(k.lower(), v) for k, v in task_details.items()]))
    elif lines[0] == "Complete":
        return (ActionType.COMPLETE, dict([(k.lower(), v) for k, v in task_details.items()]))
    
    return (ActionType.NOTHING, {})


def get_action(messages: list[ChatMessage], max_retries: int) -> tuple[ActionType, dict]:
    action_generator = LlamaAPI(api_key=os.getenv("LLAMA_API_KEY"), model="llama3.1-405b", max_tokens=4096)
    sql_generator_system_prompt = sql_generator_system_prompt.replace("CURRENT_DATE", datetime.date.today().strftime(format='%d %B %Y'))
    sql_generator_system_prompt = sql_generator_system_prompt.replace("CURRENT_TIME_HOUR", datetime.datetime.now().hour)
    sql_generator_system_prompt = sql_generator_system_prompt.replace("CURRENT_TIME_MINUTE", datetime.datetime.now().minute)
    messages_ = [ChatMessage(content=action_generator_system_prompt, role=MessageRole.SYSTEM)] + list(filter(lambda message: message.role != MessageRole.SYSTEM, messages))

    try:
        action_text = str(action_generator.chat(messages=messages_, max_tokens=4096).message.content)
        return parse_action(action_text)
    except Exception as e:
        print(e, action_text)
        if max_retries == 0:
            return (ActionType.ERROR, {})
        return get_action(messages=messages, max_retries=max_retries - 1)


def perform_action(action: tuple[ActionType, dict], user_id: int):
    print(action)
    json_dict = action[1]

    if "id" in json_dict.keys():
        json_dict["task_id"] = int(json_dict["id"])
        del json_dict["id"]
    
    if action[0] == ActionType.CREATE:
        json_dict["user_id"] = user_id
        print("Json:", json_dict)
        database_response = requests.post(
            f'https://szhp6s7oqx7vr6aspphi6ugyh40fhkne.lambda-url.eu-north-1.on.aws/add_task',
            json=json_dict,
            headers={'Content-Type': 'application/json'}
        )
        print(database_response.status_code)
        print(database_response.json())

    elif action[0] == ActionType.EDIT:
        json_dict["user_id"] = user_id
        print("Json:", json_dict)
        database_response = requests.put(
            f'https://szhp6s7oqx7vr6aspphi6ugyh40fhkne.lambda-url.eu-north-1.on.aws/update_task',
            json=json_dict,
            headers={'Content-Type': 'application/json'}
        )
        print(database_response.status_code)
        print(database_response.json())

    elif action[0] == ActionType.COMPLETE:
        print("Json:", json_dict)
        database_response = requests.delete(
            f'https://szhp6s7oqx7vr6aspphi6ugyh40fhkne.lambda-url.eu-north-1.on.aws/delete_task?task_id={json_dict["task_id"]}',
            headers={'Content-Type': 'application/json'}
        )
        print(database_response.status_code)
        print(database_response.json())


@app.get('/get_response')
def get_response(user_id: int):
    """
    This function is called whenever the server receives a /get_response request. It calls an LLM to
    generate a response to the last message of the user with the given ID, taking into account all of
    their previous message history.

    Parameters
    ----------
    user_id : int
        The ID of the user the assistant needs to respond to
    
    Returns
    -------
    JSONResponse
        A JSON in the format {"response": str} with the assistant's response to the user's last message.
    """
    # Load the user's message history
    messages = load_message_history(user_id, message_limit=10)
    print("Loaded message history:", len(messages))

    # Load any data the assistant finds necessary to fulfill the last query of the user
    data = get_data(messages, user_id, max_retries=5)
    if data.content != 'Error: {"reason": "The query is empty"}':
        messages.append(data)
    print("Loaded data:", messages[-1].content)
    
    # Call the LLM to generate a response to the user's query
    response = str(assistant.chat(
        messages=[ChatMessage(content=ASSISTANT_SYSTEM_PROMPT, role=MessageRole.SYSTEM)]
            + messages,
        max_tokens=4096
    ).message.content)
    messages.append(ChatMessage(content=response, role=MessageRole.ASSISTANT))
    print("Generated a response:", response)

    # Call the LLM to decide what task planner action needs to be performed (if any)
    action = get_action(messages=messages, max_retries=3)
    perform_action(action, user_id)
    print("Performed an action:", action)

    return JSONResponse({"response": response})


if __name__ == "__main__":
    # Run the server
    uvicorn.run(app, host="127.0.0.1", port=8001, log_config="log.ini")