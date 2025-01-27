FROM public.ecr.aws/lambda/python:3.11

# Copy requirements.txt
COPY requirements.txt ${LAMBDA_TASK_ROOT}

# Install the specified packages
RUN pip install -r requirements.txt

# Copy function code
COPY log.ini ${LAMBDA_TASK_ROOT}
COPY .env ${LAMBDA_TASK_ROOT}
COPY app.py ${LAMBDA_TASK_ROOT}

# Set the CMD to my handler
CMD [ "app.handler" ]