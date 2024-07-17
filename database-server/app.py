from fastapi import FastAPI
from fastapi.responses import JSONResponse
import uvicorn
from mangum import Mangum
import mysql.connector
from dotenv import load_dotenv
import os

app = FastAPI()
handler = Mangum(app)
cursor = None

@app.get('/get_user/')
def get_user(username: str="", email: str=""):
     if username == "" and email == "":
          return JSONResponse({"response": "Neither username not email were provided."})
     if username == "":
          cursor.execute(f"""SELECT * FROM Users WHERE EmailAddress = '{email}'""")
     elif email == "":
          cursor.execute(f"""SELECT * FROM Users WHERE Username = '{username}'""")
     else:
          cursor.execute(f"""SELECT * FROM Users WHERE Username = '{username}' AND EmailAddress = '{email}'""")
     result = cursor.fetchall()
     return JSONResponse(result)

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