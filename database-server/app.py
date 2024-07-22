from fastapi import FastAPI
from fastapi.responses import JSONResponse
import uvicorn
from mangum import Mangum
import mysql.connector
from dotenv import load_dotenv
import os
import re

app = FastAPI()
handler = Mangum(app)
cursor = None


@app.get('/get_user/')
def get_user(username: str="", email: str=""):
     if username == "" and email == "":
          return JSONResponse({"reason": "Neither username not email were provided."}, status_code=400)
     if username == "":
          cursor.execute(f"""SELECT * FROM Users WHERE EmailAddress = '{email}'""")
     elif email == "":
          cursor.execute(f"""SELECT * FROM Users WHERE Username = '{username}'""")
     else:
          cursor.execute(f"""SELECT * FROM Users WHERE Username = '{username}' AND EmailAddress = '{email}'""")
     result = cursor.fetchone()
     return JSONResponse({"data": result[0]})


@app.post('/add_user/')
def add_user(username: str, email: str, password_hash: str):
     # Check whether the username is valid
     if not (3 <= len(username) <= 32):
          return JSONResponse({"reason": "The username is not between 3 and 32 characters long"}, status_code=400)
     cursor.execute(f"""SELECT * FROM Users WHERE Username = '{username}'""")
     if len(cursor.fetchall()) > 0:
          return JSONResponse({"reason": "A user with this username already exists"}, status_code=400)
     
     # Check whether the email is valid
     EMAIL_REGEX = "^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$"
     if not re.search(EMAIL_REGEX, email):
          return JSONResponse({"reason": "The email is not in the format example@address.com"}, status_code=400)
     cursor.execute(f"""SELECT * FROM Users WHERE EmailAddress = '{email}'""")
     if len(cursor.fetchall()) > 0:
          return JSONResponse({"reason": "A user with this email address already exists"}, status_code=400)
     
     # Check whether the password hash is valid
     if len(password_hash) != 64:
          return JSONResponse({"reason": "The password hash is not 64 characters long"}, status_code=400)
     
     # Insert the data
     try:
          cursor.execute(f"""INSERT INTO Users VALUES (NULL, '{username}', '{email}', '{password_hash}')""")
          # db.commit()  # Uncomment before deployment
          return JSONResponse({}, status_code=201)
     except Exception as e:
          print(e)
          return JSONResponse({"reason": "Unknown error when inserting the data"}, status_code=400)


@app.delete('/delete_user/')
def delete_user(username: str="", email: str=""):
     if username == "" and email == "":
          return JSONResponse({"reason": "Neither username not email were provided."}, status_code=400)
     if username == "":
          cursor.execute(f"""DELETE FROM Users WHERE EmailAddress = '{email}'""")
     elif email == "":
          cursor.execute(f"""DELETE FROM Users WHERE Username = '{username}'""")
     else:
          cursor.execute(f"""DELETE FROM Users WHERE Username = '{username}' AND EmailAddress = '{email}'""")
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