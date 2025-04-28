from dotenv import load_dotenv
import os
from google.oauth2 import id_token
from google.auth.transport import requests

load_dotenv()

def handler(event, context):
    """
    This is an AWS Lambda function handler that verifies the provided Google
    ID token and returns the corresponding Google account ID

    Parameters
    ----------
    event : dict
        The packet sent to the server. Contains information such as headers,
        body and query string parameters (parameters that are provided in the
        URL). Google ID token should be passed as a query string parameter.
    context : Context
        The data about the execution environment of the AWS Lambda function
    
    Returns
    -------
    dict
        {"userID": the corresponding Google account ID}
    """
    # Extract query parameters
    query_params = event.get("queryStringParameters", {})
    google_id_token = query_params.get("google_id_token")

    # Verify Google ID token
    try:
        id_info = id_token.verify_firebase_token(
            google_id_token,
            requests.Request(),
            os.getenv("GOOGLE_CLIENT_ID")
        )
        user_id = id_info['sub']
        
        return {"userID": user_id}
    except:
        return {"error": "Invalid Google ID token"}
