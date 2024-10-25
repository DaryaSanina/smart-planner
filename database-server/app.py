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

app = FastAPI()
handler = Mangum(app)

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
     password_hash: str


class Task(BaseModel):
     name: str
     description: Optional[str] = None
     deadline: Optional[datetime.datetime] = None  # In a POST request, it should be a string of the following format: "YYYY-MM-DD[T]HH:MM:SS"
     start: Optional[datetime.datetime] = None  # In a POST request, it should be a string of the following format: "YYYY-MM-DD[T]HH:MM:SS"
     end: Optional[datetime.datetime] = None  # In a POST request, it should be a string of the following format: "YYYY-MM-DD[T]HH:MM:SS"
     importance: int
     user_id: int


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

@app.get('/')
def default():
     return JSONResponse("Nothing here.")


@app.get('/get_user')
def get_user(user_id=0, username="", email=""):
     if user_id == 0 and username == "" and email == "":
          return JSONResponse({"reason": "Neither username not email were provided."}, status_code=400)
     if user_id == 0 and username == "":
          cursor.execute(f"""SELECT * FROM Users WHERE EmailAddress = '{email}'""")
     elif user_id == 0 and email == "":
          cursor.execute(f"""SELECT * FROM Users WHERE Username = '{username}'""")
     elif username == "" and email == "":
          cursor.execute(f"""SELECT * FROM Users WHERE UserID = {user_id}""")
     elif user_id == 0:
          cursor.execute(f"""SELECT * FROM Users WHERE Username = '{username}' AND EmailAddress = '{email}'""")
     elif username == "":
          cursor.execute(f"""SELECT * FROM Users WHERE UserID = {user_id} AND EmailAddress = '{email}'""")
     elif email == "":
          cursor.execute(f"""SELECT * FROM Users WHERE UserID = {user_id} AND Username = '{username}'""")
     else:
          cursor.execute(f"""SELECT * FROM Users WHERE UserID = {user_id} Username = '{username}' AND EmailAddress = '{email}'""")
     result = cursor.fetchall()
     return JSONResponse({"data": result})


@app.post('/add_user')
def add_user(user: User):
     # Check whether the username is valid
     if not (3 <= len(user.username) <= 32):
          return JSONResponse({"reason": "The username is not between 3 and 32 characters long"}, status_code=400)
     cursor.execute(f"""SELECT * FROM Users WHERE Username = '{user.username}'""")
     if len(cursor.fetchall()) > 0:
          return JSONResponse({"reason": "A user with this username already exists"}, status_code=400)
     
     # Check whether the email is valid
     EMAIL_REGEX = "^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$"
     if not re.search(EMAIL_REGEX, user.email):
          return JSONResponse({"reason": "The email is not in the format example@address.com"}, status_code=400)
     cursor.execute(f"""SELECT * FROM Users WHERE EmailAddress = '{user.email}'""")
     if len(cursor.fetchall()) > 0:
          return JSONResponse({"reason": "A user with this email address already exists"}, status_code=400)
     
     # Check whether the password hash is valid
     if len(user.password_hash) != 64:
          return JSONResponse({"reason": "The password hash is not 64 characters long"}, status_code=400)
     
     # Insert the data
     cursor.execute(f"""INSERT INTO Users VALUES (NULL, '{user.username}', '{user.email}', '{user.password_hash}')""")
     db.commit()  # Uncomment before deployment
     return JSONResponse({"id": cursor.lastrowid}, status_code=201)


@app.delete('/delete_user')
def delete_user(user_id: int):
     cursor.execute(f"""DELETE FROM Users WHERE UserID = {user_id}""")
     db.commit()
     return JSONResponse({})


@app.get('/get_task')
def get_task(task_id=0, task_name="", user_id=0):
     if task_name == "" and task_id == 0 and user_id == 0:
          return JSONResponse({"reason": "Neither the name of the task nor its ID were provided."}, status_code=400)
     elif task_name == "" and user_id == 0:
          cursor.execute(f"""SELECT * FROM Tasks WHERE TaskID = {task_id}""")
     elif task_id == 0 and user_id == 0:
          cursor.execute(f"""SELECT * FROM Tasks WHERE Name = '{task_name}'""")
     elif task_id == 0 and task_name == "":
          cursor.execute(f"""SELECT * FROM Tasks WHERE UserID = {user_id}""")
     elif task_name == "":
          cursor.execute(f"""SELECT * FROM Tasks WHERE UserID = {user_id} AND TaskID = {task_id}""")
     elif task_id == 0:
          cursor.execute(f"""SELECT * FROM Tasks WHERE Name = '{task_name}' AND UserID = {user_id}""")
     elif user_id == 0:
          cursor.execute(f"""SELECT * FROM Tasks WHERE TaskID = {task_id} AND Name = '{task_name}'""")
     else:
          cursor.execute(f"""SELECT * FROM Tasks WHERE TaskID = {task_id} AND Name = '{task_name}' AND UserID = {user_id}""")
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
     cursor.execute(f"""SELECT * FROM Tasks JOIN TasksToTags ON (Tasks.TaskID = TasksToTags.TaskID) WHERE TagID = {tag_id}""")
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
          return JSONResponse({"reason": f"The task should either have a deadline or a start and an end date and time"}, status_code=400)
     
     # Check whether the user with this ID exists
     cursor.execute(f"""SELECT * FROM Users WHERE UserID = {task.user_id}""")
     if len(cursor.fetchall()) == 0:
          return JSONResponse({"reason": "The user with this ID does not exist"}, status_code=400)
     
     # Insert the data
     if task.deadline:
          deadline = task.deadline.strftime("%Y-%m-%d %H:%M:%S")
          cursor.execute(f"""INSERT INTO Tasks VALUES (NULL, '{task.name}', '{task.description}', '{deadline}', NULL, NULL, {task.importance}, {task.user_id})""")
     elif task.start and task.end:
          start = task.start.strftime("%Y-%m-%d %H:%M:%S")
          end = task.end.strftime("%Y-%m-%d %H:%M:%S")
          cursor.execute(f"""INSERT INTO Tasks VALUES (NULL, '{task.name}', '{task.description}', NULL, '{start}', '{end}', {task.importance}, {task.user_id})""")
     db.commit()  # Uncomment before deployment
     return JSONResponse({"id": cursor.lastrowid}, status_code=201)


@app.put('/update_task')
def update_task(task: ExistingTask):
     # Check whether the task with this ID exists
     cursor.execute(f"""SELECT * FROM Tasks WHERE TaskID = '{task.task_id}'""")
     if len(cursor.fetchall()) == 0:
          return JSONResponse({"reason": "The task with this ID does not exist"}, status_code=400)
     
     updates = []
     
     if task.name is not None:
          if not (3 <= len(task.name) <= 50):
               return JSONResponse({"reason": "The task name is not between 3 and 50 characters long"}, status_code=400)
          updates.append(f"Name = '{task.name}'")
     
     if task.description is not None:
          updates.append(f"Description = '{task.description}'")
     
     if task.importance is not None:
          if not (0 <= task.importance <= 10):
               return JSONResponse({"reason": "The importance is not between 0 and 10"}, status_code=400)
          updates.append(f"Importance = {task.importance}")
     
     if task.deadline:
          if task.start or task.end:
               return JSONResponse({"reason": "The task should either have a deadline or a start and an end date and time"}, status_code=400)
          updates.append(f"Deadline = '{task.deadline}'")
     
     if task.start or task.end:
          if task.deadline or not task.start or not task.end:
               return JSONResponse({"reason": "The task should either have a deadline or a start and an end date and time"}, status_code=400)
          updates.append(f"Start = '{task.start}', End = '{task.end}'")
     
     if len(updates) > 0:
          statement = "UPDATE Tasks SET " + ", ".join(updates) + f" WHERE TaskID = {task.task_id}"
          cursor.execute(statement)
          db.commit()  # Uncomment before deployment
     return JSONResponse({}, status_code=201)


@app.delete('/delete_task')
def delete_task(task_id: int):
     cursor.execute(f"""DELETE FROM TasksToTags WHERE TaskID = {task_id}""")  # Delete all the tag connections for this task
     cursor.execute(f"""DELETE FROM Reminders WHERE TaskID = {task_id}""")  # Delete all the reminders for this task
     cursor.execute(f"""DELETE FROM Tasks WHERE TaskID = {task_id}""")  # Delete the task
     db.commit()
     return JSONResponse({})


@app.get('/get_tag')
def get_tag(tag_id=0, tag_name="", user_id=0):
     if tag_name == "" and tag_id == 0 and user_id == 0:
          return JSONResponse({"reason": "Neither the name of the tag nor its ID nor user ID were provided."}, status_code=400)
     if tag_name == "" and user_id == 0:
          cursor.execute(f"""SELECT * FROM Tags WHERE TagID = {tag_id}""")
     elif tag_id == 0 and user_id == 0:
          cursor.execute(f"""SELECT * FROM Tags WHERE Name = '{tag_name}'""")
     elif tag_name == "" and tag_id == 0:
          cursor.execute(f"""SELECT * FROM Tags WHERE UserID = {user_id}""")
     elif user_id == 0:
          cursor.execute(f"""SELECT * FROM Tags WHERE TagID = {tag_id} AND Name = '{tag_name}'""")
     elif tag_id == 0:
          cursor.execute(f"""SELECT * FROM Tags WHERE UserID = {tag_id} AND Name = '{tag_name}'""")
     elif tag_name == "":
          cursor.execute(f"""SELECT * FROM Tags WHERE TagID = {tag_id} AND UserID = {user_id}""")
     else:
          cursor.execute(f"""SELECT * FROM Tags WHERE TagID = {tag_id} AND Name = '{tag_name}'""")
     result = cursor.fetchall()
     return JSONResponse({"data": result})


@app.post('/add_tag')
def add_tag(tag: Tag):
     # Check whether the tag name is valid
     if not (3 <= len(tag.name) <= 32):
          return JSONResponse({"reason": "The tag name is not between 3 and 32 characters long"}, status_code=400)
     
     # Check whether the user with this ID exists
     cursor.execute(f"""SELECT * FROM Users WHERE UserID = {tag.user_id}""")
     if len(cursor.fetchall()) == 0:
          return JSONResponse({"reason": "The user with this ID does not exist"}, status_code=400)
     
     # Insert the data
     cursor.execute(f"""INSERT INTO Tags VALUES (NULL, '{tag.name}', {tag.user_id})""")
     db.commit()  # Uncomment before deployment
     return JSONResponse({"id": cursor.lastrowid}, status_code=201)


@app.put('/update_tag')
def update_tag(tag_id: int, tag_name: str):
     # Check whether the tag with this ID exists
     cursor.execute(f"""SELECT * FROM Tags WHERE TagID = {tag_id}""")
     if len(cursor.fetchall()) == 0:
          return JSONResponse({"reason": "The tag with this ID does not exist"}, status_code=400)
     
     # Check whether the tag name is valid
     if not (3 <= len(tag_name) <= 32):
          return JSONResponse({"reason": "The tag name is not between 3 and 32 characters long"}, status_code=400)
     
     # Update the database
     cursor.execute(f"""UPDATE Tags SET Name = '{tag_name}' WHERE TagID = {tag_id}""")
     db.commit()  # Uncomment before deployment
     return JSONResponse({}, status_code=201)


@app.delete('/delete_tag')
def delete_tag(tag_id: int):
     cursor.execute(f"""DELETE FROM Tags WHERE TagID = {tag_id}""")
     db.commit()
     return JSONResponse({})


@app.get('/get_task_to_tag_relationship')
def get_task_to_tag_relationship(task_to_tag_id: int=None, task_id: int=None, tag_id: int=None):
     if task_to_tag_id:
          cursor.execute(f"""SELECT * FROM TasksToTags WHERE TaskToTagID = {task_to_tag_id}""")
     elif task_id and tag_id:
          cursor.execute(f"""SELECT * FROM TasksToTags WHERE TaskID = {task_id} AND TagID = {tag_id}""")
     elif task_id:
          cursor.execute(f"""SELECT * FROM TasksToTags WHERE TaskID = {task_id}""")
     elif tag_id:
          cursor.execute(f"""SELECT * FROM TasksToTags WHERE TagID = {tag_id}""")
     result = cursor.fetchall()
     return JSONResponse({"data": result})


@app.post('/add_task_to_tag_relationship')
def add_task_to_tag_relationship(task_to_tag: TaskToTag):
     # Check whether the task with this ID exists
     cursor.execute(f"""SELECT * FROM Tasks WHERE TaskID = {task_to_tag.task_id}""")
     if len(cursor.fetchall()) == 0:
          return JSONResponse({"reason": "The task with this ID does not exist"}, status_code=400)
     
     # Check whether the tag with this ID exists
     cursor.execute(f"""SELECT * FROM Tags WHERE TagID = {task_to_tag.tag_id}""")
     if len(cursor.fetchall()) == 0:
          return JSONResponse({"reason": "The tag with this ID does not exist"}, status_code=400)
     
     # Insert the data
     cursor.execute(f"""INSERT INTO TasksToTags VALUES (NULL, {task_to_tag.task_id}, {task_to_tag.tag_id})""")
     db.commit()  # Uncomment before deployment
     return JSONResponse({"id": cursor.lastrowid}, status_code=201)


@app.delete('/delete_task_to_tag_relationship')
def delete_task_to_tag_relationship(task_id: int, tag_id: int):
     cursor.execute(f"""DELETE FROM TasksToTags WHERE TaskID = {task_id} AND TagID = {tag_id}""")
     db.commit()
     return JSONResponse({})


@app.get('/get_reminder')
def get_reminder(task_id: int):
     cursor.execute(f"""SELECT * FROM Reminders WHERE TaskID = {task_id}""")
     result = cursor.fetchall()
     return JSONResponse({"data": result})


@app.post('/add_reminder')
def add_reminder(reminder: Reminder):
     # Check whether the task with this ID exists
     cursor.execute(f"""SELECT * FROM Tasks WHERE TaskID = {reminder.task_id}""")
     if len(cursor.fetchall()) == 0:
          return JSONResponse({"reason": "The task with this ID does not exist"}, status_code=400)
     
     # Check whether the reminder type is valid (between 1 and 4)
     if not (1 <= reminder.reminder_type <= 4):
          return JSONResponse({"reason": "The reminder type should be an integer between 1 and 4"}, status_code=400)
     
     # Insert the data
     cursor.execute(f"""INSERT INTO Reminders VALUES (NULL, {reminder.task_id}, {reminder.reminder_type})""")
     db.commit()  # Uncomment before deployment
     return JSONResponse({"id": cursor.lastrowid}, status_code=201)


@app.delete('/delete_reminder')
def delete_reminder(task_id: int, reminder_type: int):
     cursor.execute(f"""SELECT * FROM Reminders WHERE TaskID = {task_id} AND ReminderType = {reminder_type}""")
     result = cursor.fetchall()
     if len(result) == 0:
          return JSONResponse({"reason": "The specified reminder does not exist"}, status_code=400)
     reminder_id = result[0][0]
     cursor.execute(f"""DELETE FROM Reminders WHERE TaskID = {task_id} AND ReminderType = {reminder_type}""")
     db.commit()
     return JSONResponse({"id": reminder_id})


@app.get('/get_message')
def get_message(message_id: int):
     cursor.execute(f"""SELECT * FROM Messages WHERE MessageID = {message_id}""")
     result = cursor.fetchall()
     return JSONResponse({"data": result})


@app.post('/add_message')
def add_message(message: Message):
     # Check whether the role is 1 or 2
     if message.role != 1 and message.role != 2:
          return JSONResponse({"reason": "The role should be either 1 (user) or 2 (assistant)"}, status_code=400)
     
     # Check whether the user with this ID exists
     cursor.execute(f"""SELECT * FROM Users WHERE UserID = {message.user_id}""")
     if len(cursor.fetchall()) == 0:
          return JSONResponse({"reason": "The user with this ID does not exist"}, status_code=400)
     
     # Insert the data
     timestamp = message.timestamp.strftime("%Y-%m-%d %H:%M:%S")
     cursor.execute(f"""INSERT INTO Messages VALUES (NULL, '{message.content}', {message.role}, {timestamp}, {message.user_id})""")


@app.delete('/delete_message')
def delete_reminder(message_id: int):
     cursor.execute(f"""DELETE FROM Messages WHERE MessageID = {message_id}""")
     db.commit()
     return JSONResponse({})


if __name__ == "__main__":
    # Create the tables if they don't exist
    # Users table
    cursor.execute("""CREATE TABLE IF NOT EXISTS Users (
                        UserID INT AUTO_INCREMENT NOT NULL,
                        Username VARCHAR(32) NOT NULL,
                        EmailAddress VARCHAR(256) NOT NULL,
                        PasswordHash CHAR(64) NOT NULL,
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
                        Role VARCHAR(32) NOT NULL,
                        Timestamp DATETIME NOT NULL,
                        UserID INT NOT NULL,
                        PRIMARY KEY (MessageID),
                        FOREIGN KEY (UserID) REFERENCES Users(UserID)
                   )""")

    # Run the server
    uvicorn.run(app, host="127.0.0.1", port=8000, log_config="log.ini")