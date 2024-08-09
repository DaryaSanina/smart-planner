FROM public.ecr.aws/lambda/python:3.11

# Copy requirements.txt
COPY requirements.txt ${LAMBDA_TASK_ROOT}

# Install the specified packages
RUN pip install -r requirements.txt

# Copy function code
COPY log.ini ${LAMBDA_TASK_ROOT}
COPY word2index.pkl ${LAMBDA_TASK_ROOT}
COPY importance_embedding.pkl ${LAMBDA_TASK_ROOT}
COPY importance_model.pkl ${LAMBDA_TASK_ROOT}
COPY importance_output.pkl ${LAMBDA_TASK_ROOT}
COPY autograd.py ${LAMBDA_TASK_ROOT}
COPY layers.py ${LAMBDA_TASK_ROOT}
COPY optimisers.py ${LAMBDA_TASK_ROOT}
COPY app.py ${LAMBDA_TASK_ROOT}

# Set the CMD to my handler
CMD [ "app.handler" ]