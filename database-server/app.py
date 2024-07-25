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
cursor = None


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


@app.get('/get_user/')
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
     result = cursor.fetchone()
     return JSONResponse({"data": result[0]})


@app.post('/add_user/')
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
     #db.commit()  # Uncomment before deployment
     return JSONResponse({}, status_code=201)


@app.delete('/delete_user/')
def delete_user(user_id: int):
     cursor.execute(f"""DELETE FROM Users WHERE UserID = {user_id}""")
     return JSONResponse({})


@app.get('/get_task/')
def get_task(task_id=0, task_name=""):
     if task_name == "" and task_id == 0:
          return JSONResponse({"reason": "Neither the name of the task nor its ID were provided."}, status_code=400)
     if task_name == "":
          cursor.execute(f"""SELECT * FROM Tasks WHERE TaskID = '{task_id}'""")
     elif task_id == 0:
          cursor.execute(f"""SELECT * FROM Tasks WHERE Name = '{task_name}'""")
     else:
          cursor.execute(f"""SELECT * FROM Tasks WHERE TaskID = '{task_id}' AND Name = '{task_name}'""")
     result = cursor.fetchone()
     return JSONResponse({"data": result[0]})


@app.post('/add_task/')
def add_task(task: Task):
     # Check whether the task name is valid
     if not (3 <= len(task.name) <= 32):
          return JSONResponse({"reason": "The task name is not between 3 and 32 characters long"}, status_code=400)
     
     # Check whether the importance is valid
     if not (0 <= task.importance <= 10):
          return JSONResponse({"reason": "The importance is not between 0 and 10"}, status_code=400)
     
     # Check whether there is either a deadline or a start and an end date and time
     if not (task.deadline or (task.start and task.end)):
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
     #db.commit()  # Uncomment before deployment
     return JSONResponse({}, status_code=201)


@app.delete('/delete_task/')
def delete_task(task_id: int):
     cursor.execute(f"""DELETE FROM Tasks WHERE TaskID = {task_id}""")
     return JSONResponse({})


@app.get('/get_tag/')
def get_tag(tag_id=0, tag_name=""):
     if tag_name == "" and tag_id == 0:
          return JSONResponse({"reason": "Neither the name of the tag nor its ID were provided."}, status_code=400)
     if tag_name == "":
          cursor.execute(f"""SELECT * FROM Tags WHERE TagID = '{tag_id}'""")
     elif tag_id == 0:
          cursor.execute(f"""SELECT * FROM Tags WHERE Name = '{tag_name}'""")
     else:
          cursor.execute(f"""SELECT * FROM Tags WHERE TagID = '{tag_id}' AND Name = '{tag_name}'""")
     result = cursor.fetchone()
     return JSONResponse({"data": result[0]})


@app.post('/add_tag/')
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
     #db.commit()  # Uncomment before deployment
     return JSONResponse({}, status_code=201)


@app.delete('/delete_tag/')
def delete_tag(tag_id: int):
     cursor.execute(f"""DELETE FROM Tags WHERE TagID = {tag_id}""")
     return JSONResponse({})


if __name__ == "__main__":
    # Connect to the database
    load_dotenv()
    mysql_password = os.getenv("MYSQL_PASSWORD")
    db = mysql.connector.connect(
        host="127.0.0.1",
        port=3306,
        user="root",
        password=mysql_password,
        database="smart_planner_database"
    )
    cursor = db.cursor()

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