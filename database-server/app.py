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
     description: str | None
     deadline: datetime.datetime | None  # In a POST request, it should be a string of the following format: "YYYY-MM-DD[T]HH:MM:SS"
     start: datetime.datetime | None  # In a POST request, it should be a string of the following format: "YYYY-MM-DD[T]HH:MM:SS"
     end: datetime.datetime | None  # In a POST request, it should be a string of the following format: "YYYY-MM-DD[T]HH:MM:SS"
     importance: int
     user_id: int


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
     return JSONResponse({}, status_code=201)


@app.delete('/delete_user')
def delete_user(user_id: int):
     cursor.execute(f"""DELETE FROM Users WHERE UserID = {user_id}""")
     return JSONResponse({})


@app.get('/get_task')
def get_task(task_id=0, task_name=""):
     if task_name == "" and task_id == 0:
          return JSONResponse({"reason": "Neither the name of the task nor its ID were provided."}, status_code=400)
     if task_name == "":
          cursor.execute(f"""SELECT * FROM Tasks WHERE TaskID = '{task_id}'""")
     elif task_id == 0:
          cursor.execute(f"""SELECT * FROM Tasks WHERE Name = '{task_name}'""")
     else:
          cursor.execute(f"""SELECT * FROM Tasks WHERE TaskID = '{task_id}' AND Name = '{task_name}'""")
     result = cursor.fetchall()
     return JSONResponse({"data": result})


@app.post('/add_task')
def add_task(task: Task):
     # Check whether the task name is valid
     if not (3 <= len(task.name) <= 32):
          return JSONResponse({"reason": "The task name is not between 3 and 32 characters long"}, status_code=400)
     
     # Check whether the importance is valid
     if not (0 <= task.importance <= 10):
          return JSONResponse({"reason": "The importance is not between 0 and 10"}, status_code=400)
     
     # Check whether there is either a deadline or a start and an end date and time
     if (task.deadline and not task.start and not task.end) or (not task.deadline and task.start and task.end):
          return JSONResponse({"reason": "The task should either have a deadline or a start and an end date and time"}, status_code=400)
     
     # Check whether the user with this ID exists
     cursor.execute(f"""SELECT * FROM Users WHERE UserID = '{task.user_id}'""")
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
     return JSONResponse({}, status_code=201)


@app.put('/update_task')
def update_task(task_id: int, task_name="", description="", importance=-1, deadline=None, start=None, end=None):
     # Check whether the task with this ID exists
     cursor.execute(f"""SELECT * FROM Tasks WHERE TaskID = '{task_id}'""")
     if len(cursor.fetchall()) == 0:
          return JSONResponse({"reason": "The task with this ID does not exist"}, status_code=400)
     
     if task_name != "":
          if not (3 <= len(task_name) <= 32):
               return JSONResponse({"reason": "The task name is not between 3 and 32 characters long"}, status_code=400)
          cursor.execute(f"""UPDATE Tasks SET Name = '{task_name}' WHERE TaskID = {task_id}""")
     
     if description != "":
          cursor.execute(f"""UPDATE Tasks SET Description = '{description}' WHERE TaskID = {task_id}""")
     
     if importance != -1:
          if not (0 <= importance <= 10):
               db.rollback()
               return JSONResponse({"reason": "The importance is not between 0 and 10"}, status_code=400)
          cursor.execute(f"""UPDATE Tasks SET Importance = {importance} WHERE TaskID = {task_id}""")
     
     if deadline:
          if start or end:
               db.rollback()
               return JSONResponse({"reason": "The task should either have a deadline or a start and an end date and time"}, status_code=400)
          cursor.execute(f"""UPDATE Tasks SET Deadline = {deadline} WHERE TaskID = {task_id}""")
     
     if start or end:
          if deadline or not start or not end:
               db.rollback()
               return JSONResponse({"reason": "The task should either have a deadline or a start and an end date and time"}, status_code=400)
          cursor.execute(f"""UPDATE Tasks SET Start = {start}, End = {end} WHERE TaskID = {task_id}""")
     
     db.commit()  # Uncomment before deployment
     return JSONResponse({}, status_code=201)


@app.delete('/delete_task')
def delete_task(task_id: int):
     cursor.execute(f"""DELETE FROM Tasks WHERE TaskID = {task_id}""")
     return JSONResponse({})


@app.get('/get_tag')
def get_tag(tag_id=0, tag_name=""):
     if tag_name == "" and tag_id == 0:
          return JSONResponse({"reason": "Neither the name of the tag nor its ID were provided."}, status_code=400)
     if tag_name == "":
          cursor.execute(f"""SELECT * FROM Tags WHERE TagID = '{tag_id}'""")
     elif tag_id == 0:
          cursor.execute(f"""SELECT * FROM Tags WHERE Name = '{tag_name}'""")
     else:
          cursor.execute(f"""SELECT * FROM Tags WHERE TagID = '{tag_id}' AND Name = '{tag_name}'""")
     result = cursor.fetchall()
     return JSONResponse({"data": result})


@app.post('/add_tag')
def add_tag(tag: Tag):
     # Check whether the tag name is valid
     if not (3 <= len(tag.name) <= 32):
          return JSONResponse({"reason": "The tag name is not between 3 and 32 characters long"}, status_code=400)
     
     # Check whether the user with this ID exists
     cursor.execute(f"""SELECT * FROM Users WHERE UserID = '{tag.user_id}'""")
     if len(cursor.fetchall()) == 0:
          return JSONResponse({"reason": "The user with this ID does not exist"}, status_code=400)
     
     # Insert the data
     cursor.execute(f"""INSERT INTO Tasks VALUES (NULL, '{tag.name}', {tag.user_id})""")
     db.commit()  # Uncomment before deployment
     return JSONResponse({}, status_code=201)


@app.put('/update_tag')
def update_tag(tag_id: int, tag_name: str):
     # Check whether the tag with this ID exists
     cursor.execute(f"""SELECT * FROM Tags WHERE TagID = '{tag_id}'""")
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
     return JSONResponse({})


@app.get('/get_task_to_tag_relationship')
def get_task_to_tag_relationship(task_to_tag_id: int):
     cursor.execute(f"""SELECT * FROM TasksToTags WHERE TaskToTagID = {task_to_tag_id}""")
     result = cursor.fetchall()
     return JSONResponse({"data": result})


@app.post('/add_task_to_tag_relationship')
def add_task_to_tag_relationship(task_to_tag: TaskToTag):
     # Check whether the task with this ID exists
     cursor.execute(f"""SELECT * FROM Tasks WHERE TaskID = '{task_to_tag.task_id}'""")
     if len(cursor.fetchall()) == 0:
          return JSONResponse({"reason": "The task with this ID does not exist"}, status_code=400)
     
     # Check whether the tag with this ID exists
     cursor.execute(f"""SELECT * FROM Tags WHERE TagID = '{task_to_tag.tag_id}'""")
     if len(cursor.fetchall()) == 0:
          return JSONResponse({"reason": "The tag with this ID does not exist"}, status_code=400)
     
     # Insert the data
     cursor.execute(f"""INSERT INTO TasksToTags VALUES (NULL, {task_to_tag.task_id}, {task_to_tag.tag_id})""")
     db.commit()  # Uncomment before deployment
     return JSONResponse({}, status_code=201)


@app.delete('/delete_task_to_tag_relationship')
def delete_task_to_tag_relationship(task_to_tag_id: int):
     cursor.execute(f"""DELETE FROM TasksToTags WHERE TaskToTagID = {task_to_tag_id}""")
     return JSONResponse({})


@app.get('/get_reminder')
def get_reminder(reminder_id: int):
     cursor.execute(f"""SELECT * FROM Reminders WHERE ReminderID = {reminder_id}""")
     result = cursor.fetchall()
     return JSONResponse({"data": result})


@app.post('/add_reminder')
def add_reminder(reminder: Reminder):
     # Check whether the task with this ID exists
     cursor.execute(f"""SELECT * FROM Tasks WHERE TaskID = '{reminder.task_id}'""")
     if len(cursor.fetchall()) == 0:
          return JSONResponse({"reason": "The task with this ID does not exist"}, status_code=400)
     
     # Check whether the reminder type is valid (between 1 and 4)
     if not (1 <= reminder.reminder_type <= 4):
          return JSONResponse({"reason": "The reminder type should be an integer between 1 and 4"}, status_code=400)
     
     # Insert the data
     cursor.execute(f"""INSERT INTO Reminders VALUES (NULL, {reminder.task_id}, {reminder.reminder_type})""")
     db.commit()  # Uncomment before deployment
     return JSONResponse({}, status_code=201)


@app.delete('/delete_reminder')
def delete_reminder(reminder_id: int):
     cursor.execute(f"""DELETE FROM Reminders WHERE ReminderID = {reminder_id}""")
     return JSONResponse({})


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
     cursor.execute(f"""SELECT * FROM Users WHERE UserID = '{message.user_id}'""")
     if len(cursor.fetchall()) == 0:
          return JSONResponse({"reason": "The user with this ID does not exist"}, status_code=400)
     
     # Insert the data
     timestamp = message.timestamp.strftime("%Y-%m-%d %H:%M:%S")
     cursor.execute(f"""INSERT INTO Messages VALUES (NULL, '{message.content}', {message.role}, {timestamp}, {message.user_id})""")


@app.delete('/delete_message')
def delete_reminder(message_id: int):
     cursor.execute(f"""DELETE FROM Messages WHERE MessageID = {message_id}""")
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
                        Name VARCHAR(32) NOT NULL,
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