from fastapi import FastAPI
from fastapi.responses import JSONResponse
import uvicorn
from mangum import Mangum
from dotenv import load_dotenv
import os
from google.oauth2 import id_token
from google.auth.transport import requests
import json

load_dotenv()

def handler(event, context):
    # Extract query parameters
    query_params = event.get("queryStringParameters", {})
    google_id_token = query_params.get("google_id_token")
    print(google_id_token)

    id_info = id_token.verify_firebase_token(google_id_token, requests.Request(), os.getenv("GOOGLE_CLIENT_ID"))
    user_id = id_info['sub']
    
    return {"userID": user_id}
