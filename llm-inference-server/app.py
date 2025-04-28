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
You are an expert in task management. You assist the user in managing their
tasks. You are friendly and welcoming and eager to help the user complete their
tasks.

You can receive queries from the user as well as some relevant information about
their tasks. This information will be in the form of a JSON string which
consists of a list of tasks. This list only consists of the tasks relevant to
the problem, and as such may not contain all of the user's tasks, or may even be
empty, if no tasks are relevant to the user's problem. Each task will have a
name, a description, some time constraints (either a deadline or a start
date-time and an end date-time), and an importance level from 1 to 10. A task
may also have some of the following reminders: 10 minutes before, 1 hour before,
1 day before and 1 week before. A task can also have a list of tags it is
associated with. When the user asks you to mark a task as complete, it means
they want you to remove the task from the list. You can use this data to fulfill
the user's queries.

Remember that the user does not provide the JSON string themselves and it is
generated automatically, so do not mention it in your conversation.

You should keep your responses short.
"""

sql_generator_system_prompt = f"""
Please take into account all of the previous instructions.

You are an expert in writing SQL queries to retrieve data that might be helpful
to solve the user's problems. The problems are based around task management.

You have a database of the user's tasks. The database contains the following
tables:
1. Tasks - the user's tasks.
2. Tags - the tags the user can assign to tags.
3. TasksToTags - each record indicates that a specified tag has been assigned
to a specified task. It is a many-to-many relationship.
4. Reminders - each record indicates that a specified task has a specified
reminder. A task can have many reminders.

The Tasks table contains the following fields:
1. TaskID - INT PRIMARY KEY AUTO_INCREMENT NOT NULL - a unique identifier of the
task.
2. Name - VARCHAR(50) NOT NULL - the name or title of the task.
3. Description - TEXT - a long description of the task with detailed notes about
it.
4. Deadline - DATETIME - the deadline by which the task needs to be completed.
5. Start - DATETIME - if the task does not have a deadline, it needs to have a
start and an end (in this case it is treated more like an event).
6. End - DATETIME - see above.
7. Importance - INT NOT NULL - the task's level of importance (an integer from
1 to 10).

The Tags table contains the following fields:
1. TagID - INT PRIMARY KEY AUTO_INCREMENT NOT NULL - a unique identifier of the
tag.
2. Name - VARCHAR(32) NOT NULL - the tag's label.

The TasksToTags table contains the following fields:
1. TaskToTagID - INT PRIMARY KEY AUTO_INCREMENT - a unique ID of the
relationship between the task and the tag.
2. TaskID - INT NOT NULL FOREIGN KEY - the ID of the task that needs to be
associated with the tag.
3. TagID - INT NOT NULL FOREIGN KEY - the ID of the tag the task needs to be
associated with.

The Reminders table contains the following fields:
1. ReminderID - INT PRIMARY KEY AUTO_INCREMENT NOT NULL - a unique identifier of
the record.
2. TaskID - INT NOT NULL FOREIGN KEY - the ID of the task with the reminder
specified in this record.
3. ReminderType - INT NOT NULL - the type code for the reminder. 1 means 10
minutes before, 2 means 1 hour before, 3 means 1 day before, and 4 means 1 week
before. If the task has a start and an end instead of a deadline, the reminder
will go off the specified amount of time before the start of the task.

Here is the userID you should use: USER_ID
If needed, you can also use the following information:
Today is CURRENT_DATE
The current time is CURRENT_TIME_HOUR:CURRENT_TIME_MINUTE

You will be given the conversation between the user and another assistant and
you will need to decide whether the last query of the user needs data from the
database to be fulfilled or if it can be fulfilled more efficiently with the
data from the database and write an SQL query to get that data. You can also
decide that no data from the database is needed.

You will need to output a JSON object with a text explanation of the SQL query
and the query itself. The JSON object should have the following format:
{{
    "reasoning": The reasoning about what data needs to be retrieved and what
                 SQL command might retrieve the data or at least narrow down the
                 scope of the data. You can also decide that you don't need any
                 data at all. This should be in double quotation marks.
    "sql_query": The SQL query to retrieve the necessary data. If no data needs
                 to be retrieved, leave it blank. This should be in double
                 quotation marks.
}}

You can only write SQL SELECT queries, and the data from them will later be used
to fulfill the user's queries. You cannot alter the database yourself.
No INSERT, UPDATE or DELETE queries. Only SELECT.

Do not output anything else under any circumstances.
"""

action_generator_system_prompt = f"""
You are an expert in task management and planning. Based on the conversation
history with the user, you will need to determine whether you need to create a
task, edit a task, mark a task as done, or do nothing, and output the details
of the action. It is extremely important that you make sure to differentiate
between creating and editing a task.

If no action needs to be done, output "Nothing". This should be done in most
cases unless specifically stated by the user.

If a task needs to be created, the output should have the following format
(each thing on one separate line):
"Create"
"Name: " task name
"Description: " task description
"Importance: " task importance (an integer from 0 to 10, 0 is the lowest
importance, 10 is the highest importance)
"Deadline: " / "Start: " either the task's deadline or its start datetime
(Optional) "End: " the task's end datetime (if it has a start and an end
instead of a deadline)

If a task needs to be edited, the output should have the following format
(each thing on one separate line, task id should ALWAYS be present):
"Edit"
"Id: " task id (you will have the information about the task id in the message
history)
<field name>: new value (this line can be repeated multiple times, if multiple
fields need to be updated)

If a task needs to be marked as done, the output should have the following
format (each thing on one separate line):
"Complete"
"Id: " task id

All dates should be in one of the following formats: "YYYY-MM-DD" or
"YYYY-MM-DD[T]HH:MM"

If need, you can also use the following information:
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

# Initialise the LLM (Llama 3.1-8B)
load_dotenv()
DEFAULT_NUM_OUTPUTS = 4096
assistant = LlamaAPI(
    api_key=os.getenv("LLAMA_API_KEY"),
    model="llama3.1-8b",
    max_tokens=4096
)


def load_message_history(
        user_id: int,
        message_limit: int | None = None
) -> list[ChatMessage]:
    """
    Requests the message history of the user with the given ID and returns it
    as a list of chat messages, including the user's messages, the assistant's
    messages, and the responses of any external tools, such as database queries,
    called by the assistant.

    Parameters
    ----------
    user_id : int
        The ID of the user to retrieve the message history from
    message_limit : int
        The maximum limit on the number of messages to be retrieved (starting
        from the latest message).
        If the limit is not specified, the whole message history will be
        retrieved.
    
    Returns
    -------
    list[ChatMessage]
        A list of chat messages that can be passed to an LLM to generate a
        response to the last message. Each message is marked with either a
        "user", an "assistant" or a "system" role.
    """

    # Request the user's message history
    response = requests.get(
        'https://tiavyhhg2ajtw7j4iohc4j2tsi0zsnty.lambda-url.eu-west-2.on.aws'
            + f'/get_messages?user_id={user_id}'
    )
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


def get_data(
        messages: list[ChatMessage],
        user_id: int,
        max_attempts: int
    ) -> ChatMessage:
    global sql_generator_system_prompt
    """
    In this function, an LLM analyses the last query of the user any previous
    conversation between the user and the assistant, decides which data it will
    need to perform the user's query and retrieves the data from the database
    server.

    Parameters
    ----------
    messages : list[ChatMessage]
        A conversation between the user and the assistant.
    max_attempts : int
        The maximum number of times the LLM can repeat the data retrieval
        process, if there are any errors or the retrieved data is irrelevant to
        the query. If there are any such errors after the last attempt, the
        function will return a message without any data.
    
    Returns
    -------
    ChatMessage
        The content of the message is a JSON string with all the retrieved data
        stored as a list of database records with specified field names for each
        record. If the LLM decides that it doesn't need any data, or the maximum
        number of retries has been exceeded, the list will be empty. The role of
        this message is always MessageRole.TOOL.
    """
    try:
        # Generate an SQL query
        sql_generator = LlamaAPI(
            api_key=os.getenv("LLAMA_API_KEY"),
            model="llama3.1-8b",
            max_tokens=4096
        )
        sql_generator_system_prompt = sql_generator_system_prompt.replace(
            "USER_ID",
            str(user_id)
        )
        sql_generator_system_prompt = sql_generator_system_prompt.replace(
            "CURRENT_DATE",
            datetime.date.today().strftime(format='%d %B %Y')
        )
        sql_generator_system_prompt = sql_generator_system_prompt.replace(
            "CURRENT_TIME_HOUR",
            str(datetime.datetime.now().hour)
        )
        sql_generator_system_prompt = sql_generator_system_prompt.replace(
            "CURRENT_TIME_MINUTE",
            str(datetime.datetime.now().minute)
        )
        output = sql_generator.chat(
            messages=[
                    ChatMessage(
                        content=sql_generator_system_prompt,
                        role=MessageRole.SYSTEM
                    )
                ]
                + messages,
            max_tokens=4096
        )
        print(messages)
        print(str(output.message.content))
        sql_query_object = json.loads(output.message.content)

        # Pass the SQL query to the database server
        database_response = requests.post(
            'https://tiavyhhg2ajtw7j4iohc4j2tsi0zsnty.lambda-url.eu-west-2'
                + '.on.aws/get_data_for_chatbot',
            json={
                "sql_query": sql_query_object["sql_query"],
                "user_id": user_id
            },
            headers={'Content-Type': 'application/json'}
        )

        # If the database server has recognised the query as incorrect
        if database_response.status_code == 400 \
                and sql_query_object["sql_query"] != "":
            raise Exception(json.dumps(database_response.json()))
        
        # Retrieve the data and return it as a JSON string
        data = "Empty result"

        if database_response != "":
            data = database_response.json()["data"]
            
        assistant_response = ChatMessage(
            content=json.dumps(data), role=MessageRole.TOOL)

        return assistant_response

    except Exception as e:
        error_message = ChatMessage(
            content="Error: " + str(e),
            role=MessageRole.TOOL
        )
        if max_attempts == 1:
            return error_message
        else:
            return get_data(messages + [error_message], user_id, max_attempts=max_attempts - 1)


def parse_action(action_text: str) -> tuple[ActionType, dict]:
    """
    Receives the action LLM's response, parses it and returns the type of action
    the LLM has decided to take and the parameters of the action.

    Parameters
    ----------
    action_text : str
        The action LLM's response
    
    Returns
    -------
    ActionType
        The type of action the LLM has decided to take:
         - ActionType.CREATE to create a new task
         - ActionType.EDIT to edit a task
         - ActionType.COMPLETE to mark a task as complete
         - ActionType.NOTHING to not perform any action
    dict
        The parameters of the action.
        - For an ActionType.CREATE action the parameters are the details of the
          task, such as its name, description, importance level, deadline,
          start datetime and end datetime.
        - For an ActionType.EDIT action the parameters are the ID of the task
          and its details that need to be changed
        - For an ActionType.COMPLETE action, the only parameter is the ID of the
          task that needs to be marked as completed
    """
    lines = action_text.split('\n')
    task_details = dict(
        list(map(lambda x: tuple(x.lower().split(': ')), lines[1::]))
    )

    if lines[0] == "Create":
        return (
            ActionType.CREATE,
            dict([(k.lower(), v) for k, v in task_details.items()])
        )
    elif lines[0] == "Edit":
        return (
            ActionType.EDIT,
            dict([(k.lower(), v) for k, v in task_details.items()])
        )
    elif lines[0] == "Complete":
        return (
            ActionType.COMPLETE,
            dict([(k.lower(), v) for k, v in task_details.items()])
        )
    
    return (ActionType.NOTHING, {})


def get_action(
        messages: list[ChatMessage],
        max_attempts: int
) -> tuple[ActionType, dict]:
    print("Get action")
    """
    Generates the action LLM's response based on recent dialogue between the
    user and the assistant. This function is usually called after the assistant
    has generated a response that will be displayed to the user. The action LLM
    identifies what action would be the most appropriate to take at the moment
    and outputs it in the format described in its system message. The function
    then calls the parse_action function to convert the action LLM's response
    into the type of action it would like to take and the parameters of the
    action.

    Parameters
    ----------
    messages : list[ChatMessage]
        A list of the most recent messages in the conversation between the user
        and the assistant
    max_attempts : int
        The number of attempts given to the action LLM to generate a response
        according to the format described in the system message. If the
        parse_action function returns ActionType.ERROR and max_attempts > 0,
        the function will call itself again and decrease max_attempts by 1,
        thus allowing the LLM to generate a response again.
    
    Returns
    -------
    ActionType
        The type of action the LLM has decided to take:
         - ActionType.CREATE to create a new task
         - ActionType.EDIT to edit a task
         - ActionType.COMPLETE to mark a task as complete
         - ActionType.ERROR if the function has encountered an error while
           parsing the LLM's response
         - ActionType.NOTHING to not perform any action
    dict
        The parameters of the action.
        - For an ActionType.CREATE action the parameters are the details of the
          task, such as its name, description, importance level, deadline,
          start datetime and end datetime.
        - For an ActionType.EDIT action the parameters are the ID of the task
          and its details that need to be changed
        - For an ActionType.COMPLETE action, the only parameter is the ID of the
          task that needs to be marked as completed
    """
    global action_generator_system_prompt

    # Add the current date and time to the action LLM's system prompt
    # so that it can use them to generate actions that require them
    # (e.g., if the user has asked the assistant to create a task and set the
    # deadline for tomorrow)
    action_generator_system_prompt = action_generator_system_prompt.replace(
        "CURRENT_DATE",
        datetime.date.today().strftime(format='%d %B %Y')
    )
    action_generator_system_prompt = action_generator_system_prompt.replace(
        "CURRENT_TIME_HOUR",
        str(datetime.datetime.now().hour)
    )
    action_generator_system_prompt = action_generator_system_prompt.replace(
        "CURRENT_TIME_MINUTE",
        str(datetime.datetime.now().minute)
    )
    print("Modified system prompt")

    # Initialise the action LLM
    action_generator = LlamaAPI(
        api_key=os.getenv("LLAMA_API_KEY"),
        model="llama3.1-8b", max_tokens=4096,
        system_prompt=action_generator_system_prompt
    )

    # Remove all previous system messages and add this system message to the
    # list of messages that will be passed to the LLM
    messages_ = [
        ChatMessage(
            content=action_generator_system_prompt,
            role=MessageRole.SYSTEM
        )
    ] + list(
        filter(lambda message: message.role != MessageRole.SYSTEM, messages)
    )

    # Make sure that the last message is either the user's request or the
    # response from the database
    while len(messages_) > 0 and messages_[-1].role == MessageRole.ASSISTANT:
        messages_.pop()
    print("Updated messages")
    print(messages_)

    try:
        # Query the action LLM to generate a response
        action_text = str(
            action_generator.chat(
                messages=messages_,
                max_tokens=4096
            ).message.content
        )
        print("Generated an action text:", action_text)
        if action_text == "":
            raise Exception

        # Convert the action LLM's response into the type of action it would
        # like to take and the parameters of the action
        print(parse_action(action_text))
        return parse_action(action_text)
    
    except Exception as e:
        # If there are no attempts left, return ActionType.ERROR
        if max_attempts == 1:
            return (ActionType.ERROR, {})
        
        # Otherwise, try again
        return get_action(messages=messages, max_attempts=max_attempts - 1)


def perform_action(action: tuple[ActionType, dict], user_id: int) -> None:
    """
    Performs an action that the action LLM has decided to take by sending a
    request to the database server.

    Parameters
    ----------
    action : tuple[ActionType, dict]
        ActionType
            The type of action the LLM has decided to take:
             - ActionType.CREATE to create a new task
             - ActionType.EDIT to edit a task
             - ActionType.COMPLETE to mark a task as complete
             - ActionType.ERROR if the function has encountered an error while
               parsing the LLM's response
             - ActionType.NOTHING to not perform any action
        dict
            The parameters of the action.
             - For an ActionType.CREATE action the parameters are the details of
               the task, such as its name, description, importance level,
               deadline, start datetime and end datetime.
             - For an ActionType.EDIT action the parameters are the ID of the
               task and its details that need to be changed
             - For an ActionType.COMPLETE action, the only parameter is the ID
               of the task that needs to be marked as completed
    user_id : int
        The ID of the user on whose tasks the action needs to be performed
    """
    json_dict = action[1]

    # Replace any "id" attributes with "task_id"
    if "id" in json_dict.keys():
        json_dict["task_id"] = int(json_dict["id"])
        del json_dict["id"]
    
    # Add a task to the database
    if action[0] == ActionType.CREATE:
        json_dict["user_id"] = user_id
        requests.post(
            'https://tiavyhhg2ajtw7j4iohc4j2tsi0zsnty.lambda-url.eu-west-2'
                + '.on.aws/add_task',
            json=json_dict,
            headers={'Content-Type': 'application/json'}
        )

    # Update a task in the database
    elif action[0] == ActionType.EDIT:
        json_dict["user_id"] = user_id
        requests.put(
            'https://tiavyhhg2ajtw7j4iohc4j2tsi0zsnty.lambda-url.eu-west-2'
                + '.on.aws/update_task',
            json=json_dict,
            headers={'Content-Type': 'application/json'}
        )

    # Delete a task from the database
    elif action[0] == ActionType.COMPLETE:
        requests.delete(
            'https://tiavyhhg2ajtw7j4iohc4j2tsi0zsnty.lambda-url.eu-west-2'
                + f'.on.aws/delete_task?task_id={json_dict["task_id"]}',
            headers={'Content-Type': 'application/json'}
        )


@app.get('/get_response')
def get_response(user_id: int):
    """
    This function is called whenever the server receives a /get_response
    request. It calls an LLM to generate a response to the last message of the
    user with the given ID, taking into account all of their previous message
    history.

    Parameters
    ----------
    user_id : int
        The ID of the user the assistant needs to respond to
    
    Returns
    -------
    JSONResponse
        A JSON in the format {"response": str} with the assistant's response to
        the user's last message.
    """
    # Load the user's message history
    messages = load_message_history(user_id, message_limit=10)

    # Load any data the assistant finds necessary to fulfill the last query of
    # the user
    data = get_data(messages, user_id, max_attempts=3)
    if data.content != 'Error: {"reason": "The query is empty"}':
        messages.append(data)

        # Send a message with the data to the database
        requests.post(
            'https://tiavyhhg2ajtw7j4iohc4j2tsi0zsnty.lambda-url.eu-west-2'
                + '.on.aws/get_data_for_chatbot',
            json={
                "content": data.content,
                "role": 3,
                "timestamp": datetime.datetime.now().isoformat(),
                "user_id": user_id
            },
            headers={'Content-Type': 'application/json'}
        )
    
    # Call the LLM to generate a response to the user's query
    response = str(
        assistant.chat(
            messages=[
                ChatMessage(
                    content=ASSISTANT_SYSTEM_PROMPT,
                    role=MessageRole.SYSTEM
                )
            ]
            + messages,
            max_tokens=4096
        ).message.content
    )
    print(response)
    messages.append(ChatMessage(content=response, role=MessageRole.ASSISTANT))

    # Call the LLM to decide what task planner action needs to be performed
    # (if any)
    print("Call to get action")
    action = get_action(messages=messages, max_attempts=3)
    perform_action(action, user_id)

    return JSONResponse({"response": response})


if __name__ == "__main__":
    # Run the server
    uvicorn.run(app, host="127.0.0.1", port=8001, log_config="log.ini")