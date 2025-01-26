from fastapi import FastAPI
from fastapi.responses import JSONResponse
import uvicorn
from mangum import Mangum
import mysql.connector
from dotenv import load_dotenv
import os
import re
from pydantic import BaseModel
import datetime
from typing import Optional
import boto3
import json

app = FastAPI()
handler = Mangum(app)
lambda_client = boto3.client('lambda')

# Connect to the database
load_dotenv()
mysql_password = os.getenv("MYSQL_PASSWORD")
mysql_host = os.getenv("MYSQL_HOST")
db = mysql.connector.connect(
    host=mysql_host,
    port=3306,
    user="admin",
    password=mysql_password,
    database="smart_planner_database"
)
cursor = db.cursor()


class User(BaseModel):
    username: str
    email: str
    password_hash: Optional[str] = None


class Task(BaseModel):
    name: str
    description: Optional[str] = None
    deadline: Optional[datetime.datetime] = None  # In a POST request, it should be a string of the following format: "YYYY-MM-DD[T]HH:MM:SS"
    start: Optional[datetime.datetime] = None  # In a POST request, it should be a string of the following format: "YYYY-MM-DD[T]HH:MM:SS"
    end: Optional[datetime.datetime] = None  # In a POST request, it should be a string of the following format: "YYYY-MM-DD[T]HH:MM:SS"
    importance: int
    user_id: int
    google_calendar_event_id: Optional[str] = None


class ExistingTask(BaseModel):
    task_id: int
    name: Optional[str] = None
    description: Optional[str] = None
    deadline: Optional[datetime.datetime] = None  # In a POST request, it should be a string of the following format: "YYYY-MM-DD[T]HH:MM:SS"
    start: Optional[datetime.datetime] = None  # In a POST request, it should be a string of the following format: "YYYY-MM-DD[T]HH:MM:SS"
    end: Optional[datetime.datetime] = None  # In a POST request, it should be a string of the following format: "YYYY-MM-DD[T]HH:MM:SS"
    importance: Optional[int] = None


class Tag(BaseModel):
    name: str
    user_id: int


class TaskToTag(BaseModel):
    task_id: int
    tag_id: int


class Reminder(BaseModel):
    task_id: int
    reminder_type: int  # 1 - 10 minutes before, 2 - 1 hour before, 3 - 1 day before, 4 - 1 week before


class Message(BaseModel):
    content: str
    role: int  # 1 - user, 2 - assistant
    timestamp: datetime.datetime  # In a POST request, it should be a string of the following format: "YYYY-MM-DD[T]HH:MM:SS"
    user_id: int


class ChatbotQuery(BaseModel):
    reasoning : str
    sql_query : str
    user_id: int


def check_google_id_token(google_id_token: str) -> str:
    """
    Checks whether the provided Google ID token is valid and returns the user's Google account ID

    Parameters
    ----------
    google_id_token : str

    Returns
    -------
    google_id : str
    """
    url_parameters = {
        "queryStringParameters": {
            "google_id_token": google_id_token,
        }
    }
    response = lambda_client.invoke(
        FunctionName="arn:aws:lambda:eu-north-1:639191934765:function:smart_planner_google_token_id_verification",
        InvocationType='RequestResponse',
        Payload=json.dumps(url_parameters)
    )
    
    # Read and process the response
    response_payload = json.loads(response['Payload'].read().decode('utf-8'))
    print(response_payload)
    return response_payload["userID"]


@app.get('/')
def default():
    return JSONResponse("Nothing here.")


@app.get('/get_user')
def get_user(user_id=0, username="", email="", google_id_token=""):
    # Sign in with Google
    if google_id_token != "":
        try:
            google_id = check_google_id_token(google_id_token)
        except ValueError:
            return JSONResponse({"reason": "Invalid Google ID token"}, status_code=400)
        
        cursor.execute("SELECT * FROM Users WHERE GoogleID = %s", (google_id,))
        result = cursor.fetchall()
        print(google_id_token)
        print(result)
        return JSONResponse({"data": result})

    # Sign in with username and password
    print("Signing in")
    if user_id == 0 and username == "" and email == "":
        return JSONResponse({"reason": "Neither username not email were provided."}, status_code=400)
    if user_id == 0 and username == "":
        cursor.execute("SELECT * FROM Users WHERE EmailAddress = %s", (email,))
    elif user_id == 0 and email == "":
        cursor.execute("SELECT * FROM Users WHERE Username = %s", (username,))
    elif username == "" and email == "":
        cursor.execute("SELECT * FROM Users WHERE UserID = %s", (user_id,))
    elif user_id == 0:
        cursor.execute("SELECT * FROM Users WHERE Username = %s AND EmailAddress = %s", (username, email))
    elif username == "":
        cursor.execute("SELECT * FROM Users WHERE UserID = %s AND EmailAddress = %s", (user_id, email))
    elif email == "":
        cursor.execute("SELECT * FROM Users WHERE UserID = %s AND Username = %s", (user_id, username))
    else:
        cursor.execute("SELECT * FROM Users WHERE UserID = %s Username = %s AND EmailAddress = %s", (user_id, username, email))
    result = cursor.fetchall()
    return JSONResponse({"data": result})


@app.post('/add_user')
def add_user(user: User):
    # Check whether the username is valid
    if not (3 <= len(user.username) <= 32):
        return JSONResponse({"reason": "The username is not between 3 and 32 characters long"}, status_code=400)
    cursor.execute("SELECT * FROM Users WHERE Username = %s", (user.username,))
    if len(cursor.fetchall()) > 0:
        return JSONResponse({"reason": "A user with this username already exists"}, status_code=400)

    # Check whether the email is valid
    EMAIL_REGEX = "^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$"
    if not re.search(EMAIL_REGEX, user.email):
        return JSONResponse({"reason": "The email is not in the format example@address.com"}, status_code=400)
    cursor.execute("SELECT * FROM Users WHERE EmailAddress = %s", (user.email,))
    if len(cursor.fetchall()) > 0:
        return JSONResponse({"reason": "A user with this email address already exists"}, status_code=400)

    # Check whether the password hash is valid
    if len(user.password_hash) != 64:
        return JSONResponse({"reason": "The password hash is not 64 characters long"}, status_code=400)

    # Insert the data
    cursor.execute("INSERT INTO Users VALUES (NULL, %s, %s, %s, NULL)", (user.username, user.email, user.password_hash))
    db.commit()  # Uncomment before deployment
    return JSONResponse({"id": cursor.lastrowid}, status_code=201)


@app.put('/update_username')
def update_username(user_id: int, username: str):
    # Check whether the username is valid
    if not (3 <= len(username) <= 32):
        return JSONResponse({"reason": "The username is not between 3 and 32 characters long"}, status_code=400)
    cursor.execute("SELECT * FROM Users WHERE Username = %s", (username,))
    if len(cursor.fetchall()) > 0:
        return JSONResponse({"reason": "A user with this username already exists"}, status_code=400)

    # Update the data
    cursor.execute("UPDATE Users SET Username = %s WHERE UserID = %s", (username, user_id))
    db.commit()  # Uncomment before deployment
    return JSONResponse({"id": user_id}, status_code=200)


@app.put('/update_password')
def update_password(user_id: int, password_hash: str):
    # Check whether the password hash is valid
    if len(password_hash) != 64:
        return JSONResponse({"reason": "The password hash is not 64 characters long"}, status_code=400)

    # Update the data
    cursor.execute("UPDATE Users SET PasswordHash = %s WHERE UserID = %s", (password_hash, user_id))
    db.commit()  # Uncomment before deployment
    return JSONResponse({"id": user_id}, status_code=200)


@app.put('/link_google_account')
def link_google_account(user_id: int, google_id_token: str):
    try:
        google_id = check_google_id_token(google_id_token)
    except ValueError:
        return JSONResponse({"reason": "Invalid Google ID token"}, status_code=400)
    
    cursor.execute("UPDATE Users SET GoogleID = %s WHERE UserID = %s", (google_id, user_id))
    db.commit()
    return JSONResponse({"id": user_id}, status_code=200)


@app.delete('/delete_user')
def delete_user(user_id: int):
    cursor.execute("DELETE FROM Users WHERE UserID = %s", (user_id,))
    db.commit()
    return JSONResponse({})


@app.get('/get_task')
def get_task(task_id=0, task_name="", user_id=0):
    if task_name == "" and task_id == 0 and user_id == 0:
        return JSONResponse({"reason": "Neither the name of the task nor its ID were provided."}, status_code=400)
    elif task_name == "" and user_id == 0:
        cursor.execute("SELECT * FROM Tasks WHERE TaskID = %s", (task_id,))
    elif task_id == 0 and user_id == 0:
        cursor.execute("SELECT * FROM Tasks WHERE Name = %s", (task_name,))
    elif task_id == 0 and task_name == "":
        cursor.execute("SELECT * FROM Tasks WHERE UserID = %s", (user_id,))
    elif task_name == "":
        cursor.execute("SELECT * FROM Tasks WHERE UserID = %s AND TaskID = %s", (user_id, task_id))
    elif task_id == 0:
        cursor.execute("SELECT * FROM Tasks WHERE Name = %s AND UserID = %s", (task_name, user_id))
    elif user_id == 0:
        cursor.execute("SELECT * FROM Tasks WHERE TaskID = %s AND Name = %s", (task_id, task_name))
    else:
        cursor.execute("SELECT * FROM Tasks WHERE TaskID = %s AND Name = %s AND UserID = %s", (task_id, task_name, user_id))
    result = cursor.fetchall()
    result = list(result)
    for i in range(len(result)):
        result[i] = list(result[i])
        for j in range(len(result[i])):
            if type(result[i][j]) == datetime.datetime:
                result[i][j] = result[i][j].strftime("%Y-%m-%dT%H:%M:%S")
    return JSONResponse({"data": result})


@app.get('/get_tasks_by_tag')
def get_task_by_tag(tag_id: int):
    cursor.execute("SELECT * FROM Tasks JOIN TasksToTags ON (Tasks.TaskID = TasksToTags.TaskID) WHERE TagID = %s", (tag_id,))
    result = cursor.fetchall()
    result = list(result)
    return JSONResponse({"data": result})


@app.post('/add_task')
def add_task(task: Task):
    # Check whether the task name is valid
    if not (3 <= len(task.name) <= 50):
        return JSONResponse({"reason": "The task name is not between 3 and 50 characters long"}, status_code=400)

    # Check whether the importance is valid
    if not (0 <= task.importance <= 10):
        return JSONResponse({"reason": "The importance is not between 0 and 10"}, status_code=400)

    # Check whether there is either a deadline or a start and an end date and time
    if not((task.deadline is not None and task.start is None and task.end is None) or (task.deadline is None and task.start is not None and task.end is not None)):
        return JSONResponse({"reason": "The task should either have a deadline or a start and an end date and time"}, status_code=400)

    # Check whether the user with this ID exists
    cursor.execute("SELECT * FROM Users WHERE UserID = %s", (task.user_id,))
    if len(cursor.fetchall()) == 0:
        return JSONResponse({"reason": "The user with this ID does not exist"}, status_code=400)

    # Insert the data
    if task.deadline:
        deadline = task.deadline.strftime("%Y-%m-%d %H:%M:%S")
        cursor.execute("INSERT INTO Tasks VALUES (NULL, %s, %s, %s, NULL, NULL, %s, %s, %s)", (task.name, task.description, deadline, task.importance, task.user_id, task.google_calendar_event_id))
    elif task.start and task.end:
        start = task.start.strftime("%Y-%m-%d %H:%M:%S")
        end = task.end.strftime("%Y-%m-%d %H:%M:%S")
        cursor.execute("INSERT INTO Tasks VALUES (NULL, %s, %s, NULL, %s, %s, %s, %s, %s)", (task.name, task.description, start, end, task.importance, task.user_id, task.google_calendar_event_id))
    db.commit()  # Uncomment before deployment
    return JSONResponse({"id": cursor.lastrowid}, status_code=201)


@app.put('/update_task')
def update_task(task: ExistingTask):
    # Check whether the task with this ID exists
    cursor.execute("SELECT * FROM Tasks WHERE TaskID = %s", (task.task_id,))
    if len(cursor.fetchall()) == 0:
        return JSONResponse({"reason": "The task with this ID does not exist"}, status_code=400)

    updates = []

    if task.name is not None:
        if not (3 <= len(task.name) <= 50):
            return JSONResponse({"reason": "The task name is not between 3 and 50 characters long"}, status_code=400)
        updates.append("Name = '{task.name}'")

    if task.description is not None:
        updates.append("Description = '{task.description}'")

    if task.importance is not None:
        if not (0 <= task.importance <= 10):
            return JSONResponse({"reason": "The importance is not between 0 and 10"}, status_code=400)
        updates.append("Importance = {task.importance}")

    if task.deadline:
        if task.start or task.end:
            return JSONResponse({"reason": "The task should either have a deadline or a start and an end date and time"}, status_code=400)
        updates.append("Deadline = '{task.deadline}'")

    if task.start or task.end:
        if task.deadline or not task.start or not task.end:
            return JSONResponse({"reason": "The task should either have a deadline or a start and an end date and time"}, status_code=400)
        updates.append("Start = '{task.start}', End = '{task.end}'")

    if len(updates) > 0:
        statement = "UPDATE Tasks SET " + ", ".join(updates) + " WHERE TaskID = {task.task_id}"
        cursor.execute(statement)
        db.commit()  # Uncomment before deployment
    return JSONResponse({}, status_code=201)


@app.delete('/delete_task')
def delete_task(task_id: int):
    cursor.execute("DELETE FROM TasksToTags WHERE TaskID = %s", (task_id,))  # Delete all the tag connections for this task
    cursor.execute("DELETE FROM Reminders WHERE TaskID = %s", (task_id,))  # Delete all the reminders for this task
    cursor.execute("DELETE FROM Tasks WHERE TaskID = %s", (task_id,))  # Delete the task
    db.commit()
    return JSONResponse({})


@app.get('/get_tag')
def get_tag(tag_id=0, tag_name="", user_id=0):
    if tag_name == "" and tag_id == 0 and user_id == 0:
        return JSONResponse({"reason": "Neither the name of the tag nor its ID nor user ID were provided."}, status_code=400)
    if tag_name == "" and user_id == 0:
        cursor.execute("SELECT * FROM Tags WHERE TagID = %s", (tag_id,))
    elif tag_id == 0 and user_id == 0:
        cursor.execute("SELECT * FROM Tags WHERE Name = %s", (tag_name,))
    elif tag_name == "" and tag_id == 0:
        cursor.execute("SELECT * FROM Tags WHERE UserID = %s", (user_id,))
    elif user_id == 0:
        cursor.execute("SELECT * FROM Tags WHERE TagID = %s AND Name = %s", (tag_id, tag_name))
    elif tag_id == 0:
        cursor.execute("SELECT * FROM Tags WHERE UserID = %s AND Name = %s", (user_id, tag_name))
    elif tag_name == "":
        cursor.execute("SELECT * FROM Tags WHERE TagID = %s AND UserID = %s", (tag_id, user_id))
    else:
        cursor.execute("SELECT * FROM Tags WHERE UserID = %s AND TagID = %s AND Name = %s", (user_id, tag_id, tag_name))
    result = cursor.fetchall()
    return JSONResponse({"data": result})


@app.post('/add_tag')
def add_tag(tag: Tag):
    # Check whether the tag name is valid
    if not (3 <= len(tag.name) <= 32):
        return JSONResponse({"reason": "The tag name is not between 3 and 32 characters long"}, status_code=400)

    # Check whether the user with this ID exists
    cursor.execute("SELECT * FROM Users WHERE UserID = %s", (tag.user_id,))
    if len(cursor.fetchall()) == 0:
        return JSONResponse({"reason": "The user with this ID does not exist"}, status_code=400)

    # Insert the data
    cursor.execute("INSERT INTO Tags VALUES (NULL, %s, %s)", (tag.name, tag.user_id))
    db.commit()  # Uncomment before deployment
    return JSONResponse({"id": cursor.lastrowid}, status_code=201)


@app.put('/update_tag')
def update_tag(tag_id: int, tag_name: str):
    # Check whether the tag with this ID exists
    cursor.execute("SELECT * FROM Tags WHERE TagID = %s", (tag_id,))
    if len(cursor.fetchall()) == 0:
        return JSONResponse({"reason": "The tag with this ID does not exist"}, status_code=400)

    # Check whether the tag name is valid
    if not (3 <= len(tag_name) <= 32):
        return JSONResponse({"reason": "The tag name is not between 3 and 32 characters long"}, status_code=400)

    # Update the database
    cursor.execute("UPDATE Tags SET Name = %s WHERE TagID = %s", (tag_name, tag_id))
    db.commit()  # Uncomment before deployment
    return JSONResponse({}, status_code=201)


@app.delete('/delete_tag')
def delete_tag(tag_id: int):
    cursor.execute("DELETE FROM Tags WHERE TagID = %s", (tag_id,))
    db.commit()
    return JSONResponse({})


@app.get('/get_task_to_tag_relationship')
def get_task_to_tag_relationship(task_to_tag_id: int=None, task_id: int=None, tag_id: int=None):
    if task_to_tag_id:
        cursor.execute("SELECT * FROM TasksToTags WHERE TaskToTagID = %s", (task_to_tag_id,))
    elif task_id and tag_id:
        cursor.execute("SELECT * FROM TasksToTags WHERE TaskID = %s AND TagID = %s", (task_id, tag_id))
    elif task_id:
        cursor.execute("SELECT * FROM TasksToTags WHERE TaskID = %s", (task_id,))
    elif tag_id:
        cursor.execute("SELECT * FROM TasksToTags WHERE TagID = %s", (tag_id,))
    result = cursor.fetchall()
    return JSONResponse({"data": result})


@app.post('/add_task_to_tag_relationship')
def add_task_to_tag_relationship(task_to_tag: TaskToTag):
    # Check whether the task with this ID exists
    cursor.execute("SELECT * FROM Tasks WHERE TaskID = %s", (task_to_tag.task_id,))
    if len(cursor.fetchall()) == 0:
        return JSONResponse({"reason": "The task with this ID does not exist"}, status_code=400)

    # Check whether the tag with this ID exists
    cursor.execute("SELECT * FROM Tags WHERE TagID = %s", (task_to_tag.tag_id,))
    if len(cursor.fetchall()) == 0:
        return JSONResponse({"reason": "The tag with this ID does not exist"}, status_code=400)

    # Insert the data
    cursor.execute("INSERT INTO TasksToTags VALUES (NULL, %s, %s)", (task_to_tag.task_id, task_to_tag.tag_id))
    db.commit()  # Uncomment before deployment
    return JSONResponse({"id": cursor.lastrowid}, status_code=201)


@app.delete('/delete_task_to_tag_relationship')
def delete_task_to_tag_relationship(task_id: int, tag_id: int):
    cursor.execute("DELETE FROM TasksToTags WHERE TaskID = %s AND TagID = %s", (task_id, tag_id))
    db.commit()
    return JSONResponse({})


@app.get('/get_reminder')
def get_reminder(task_id: int):
    cursor.execute("SELECT * FROM Reminders WHERE TaskID = %s", (task_id,))
    result = cursor.fetchall()
    return JSONResponse({"data": result})


@app.post('/add_reminder')
def add_reminder(reminder: Reminder):
    # Check whether the task with this ID exists
    cursor.execute("SELECT * FROM Tasks WHERE TaskID = %s", (reminder.task_id,))
    if len(cursor.fetchall()) == 0:
        return JSONResponse({"reason": "The task with this ID does not exist"}, status_code=400)

    # Check whether the reminder type is valid (between 1 and 4)
    if not (1 <= reminder.reminder_type <= 4):
        return JSONResponse({"reason": "The reminder type should be an integer between 1 and 4"}, status_code=400)

    # Insert the data
    cursor.execute("INSERT INTO Reminders VALUES (NULL, %s, %s)", (reminder.task_id, reminder.reminder_type))
    db.commit()  # Uncomment before deployment
    return JSONResponse({"id": cursor.lastrowid}, status_code=201)


@app.delete('/delete_reminder')
def delete_reminder(task_id: int, reminder_type: int):
    cursor.execute("SELECT * FROM Reminders WHERE TaskID = %s AND ReminderType = %s", (task_id, reminder_type))
    result = cursor.fetchall()
    if len(result) == 0:
        return JSONResponse({"reason": "The specified reminder does not exist"}, status_code=400)
    reminder_id = result[0][0]
    cursor.execute("DELETE FROM Reminders WHERE TaskID = %s AND ReminderType = %s", (task_id, reminder_type))
    db.commit()
    return JSONResponse({"id": reminder_id})


@app.get('/get_messages')
def get_message(user_id: int):
    cursor.execute("SELECT * FROM Messages WHERE UserID = %s", (user_id,))
    result = cursor.fetchall()
    result = list(result)
    for i in range(len(result)):
        result[i] = list(result[i])
        for j in range(len(result[i])):
            if type(result[i][j]) == datetime.datetime:
                result[i][j] = result[i][j].strftime("%Y-%m-%dT%H:%M:%S")
    return JSONResponse({"data": result})


@app.post('/add_message')
def add_message(message: Message):
    # Check whether the role is 1 or 2
    if message.role != 1 and message.role != 2:
        return JSONResponse({"reason": "The role should be either 1 (user) or 2 (assistant)"}, status_code=400)

    # Check whether the user with this ID exists
    cursor.execute("SELECT * FROM Users WHERE UserID = %s", (message.user_id,))
    if len(cursor.fetchall()) == 0:
        return JSONResponse({"reason": "The user with this ID does not exist"}, status_code=400)

    # Insert the data
    timestamp = message.timestamp.strftime("%Y-%m-%d %H:%M:%S")
    cursor.execute("INSERT INTO Messages VALUES (NULL, %s, %s, %s, %s)", (message.content.replace("'", "''"), message.role, timestamp, message.user_id))

    db.commit()
    return JSONResponse({})


@app.delete('/delete_message')
def delete_reminder(message_id: int):
    cursor.execute("DELETE FROM Messages WHERE MessageID = %s", (message_id,))
    db.commit()
    return JSONResponse({})


@app.post('/get_data_for_chatbot')
def get_data_for_chatbot(query: ChatbotQuery):
    if query.sql_query == "":
        return JSONResponse({"reason": "The query is empty"}, status_code=400)

    if query.sql_query.split()[0] != "SELECT":
        return JSONResponse({"reason": "The server can only process SELECT queries"}, status_code=400)

    if "FROM" not in query.sql_query.split() or len(query.sql_query.split()) <= query.sql_query.split().index("FROM") + 1:
        return JSONResponse({"reason": "Invalid SQL query"}, status_code=400)

    table_name = query.sql_query.split()[query.sql_query.split().index("FROM") + 1]
    if table_name not in ["Tasks", "Tags", "TasksToTags", "Reminders"]:
        return JSONResponse({"reason": "The server cannot process queries to the {table_name} table. "
                            + "It can only process queries to the following tables: Tasks, Tags, TasksToTags and Reminders."}, status_code=400)

    try:
        cursor.execute(query.sql_query)
        data = cursor.fetchall()

        field_names = [field[0] for field in cursor.description]

        data = list(data)
        result = []
        for i in range(len(data)):
            data[i] = list(data[i])  # result[i] is a particular record

            # Replace datetime with a JSON-serialisable string
            for j in range(len(data[i])):
                if type(data[i][j]) == datetime.datetime:
                        data[i][j] = data[i][j].strftime("%Y-%m-%dT%H:%M:%S")

            data[i] = dict(zip(field_names, data[i]))  # Attach field names to the record

            if "UserID" not in data[i].keys() or int(data[i]["UserID"]) == query.user_id:
                result.append(data[i])

        return JSONResponse({"data": result})

    except Exception as e:
        print("reason 5")
        return JSONResponse({"reason5": "Invalid SQL query. Error: " + str(e)}, status_code=400)

if __name__ == "__main__":
    # Create the tables if they don't exist
    # Users table
    cursor.execute("""CREATE TABLE IF NOT EXISTS Users (
                        UserID INT AUTO_INCREMENT NOT NULL,
                        Username VARCHAR(32) NOT NULL,
                        EmailAddress VARCHAR(256) NOT NULL,
                        PasswordHash CHAR(64) NOT NULL,
                        GoogleID VARCHAR(256),
                        PRIMARY KEY (UserID)
                   )""")
    # Tasks table
    cursor.execute("""CREATE TABLE IF NOT EXISTS Tasks (
                        TaskID INT AUTO_INCREMENT NOT NULL,
                        Name VARCHAR(50) NOT NULL,
                        Description TEXT,
                        Deadline DATETIME,
                        Start DATETIME,
                        End DATETIME,
                        Importance INT NOT NULL,
                        UserID INT NOT NULL,
                        GoogleCalendarEventID VARCHAR(256),
                        PRIMARY KEY (TaskID),
                        FOREIGN KEY (UserID) REFERENCES Users(UserID)
                   )""")
    # Tags table
    cursor.execute("""CREATE TABLE IF NOT EXISTS Tags (
                        TagID INT AUTO_INCREMENT NOT NULL,
                        Name VARCHAR(32) NOT NULL,
                        UserID INT NOT NULL,
                        PRIMARY KEY (TagID),
                        FOREIGN KEY (UserID) REFERENCES Users(UserID)
                   )""")
    # Tasks to tags table
    cursor.execute("""CREATE TABLE IF NOT EXISTS TasksToTags (
                        TaskToTagID INT AUTO_INCREMENT NOT NULL,
                        TaskID INT NOT NULL,
                        TagID INT NOT NULL,
                        PRIMARY KEY (TaskToTagID),
                        FOREIGN KEY (TaskID) REFERENCES Tasks(TaskID),
                        FOREIGN KEY (TagID) REFERENCES Tags(TagID)
                   )""")
    # Reminders table
    cursor.execute("""CREATE TABLE IF NOT EXISTS Reminders (
                        ReminderID INT AUTO_INCREMENT NOT NULL,
                        TaskID INT NOT NULL,
                        ReminderType INT NOT NULL,
                        PRIMARY KEY (ReminderID),
                        FOREIGN KEY (TaskID) REFERENCES Tasks(TaskID)
                   )""")
    # Messages table
    cursor.execute("""CREATE TABLE IF NOT EXISTS Messages (
                        MessageID INT AUTO_INCREMENT NOT NULL,
                        Content TEXT NOT NULL,
                        Role INT NOT NULL,
                        Timestamp DATETIME NOT NULL,
                        UserID INT NOT NULL,
                        PRIMARY KEY (MessageID),
                        FOREIGN KEY (UserID) REFERENCES Users(UserID)
                   )""")

    # Run the server
    uvicorn.run(app, host="127.0.0.1", port=8000, log_config="log.ini")