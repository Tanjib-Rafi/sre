FROM python:3.11-slim

# set working directory
WORKDIR /app

# copy only requirements first for caching
COPY app/requirements.txt .

# Install dependencies
RUN pip install --no-cache-dir -r requirements.txt

# copy the rest of the app
COPY app/ .

# expose correct port
EXPOSE 8080

# start the app
CMD ["python", "main.py"]
