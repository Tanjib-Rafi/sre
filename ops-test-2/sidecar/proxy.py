from flask import Flask, request
import random
import time
import logging
from logging.handlers import RotatingFileHandler
import json
from pythonjsonlogger import jsonlogger

app = Flask(__name__)

# ------------------------
# Configure rotating JSON logs
# ------------------------
logHandler = RotatingFileHandler(
    "/var/log/test2/app.log",  # write logs to shared volume
    maxBytes=5*1024*1024,      # 5 MB per file
    backupCount=5              # keep last 5 files
)

# Use JSON format
formatter = jsonlogger.JsonFormatter(
    '%(asctime)s %(levelname)s %(name)s %(message)s'
)
logHandler.setFormatter(formatter)
logHandler.setLevel(logging.INFO)

# Add handler to Flask logger
app.logger.addHandler(logHandler)
app.logger.setLevel(logging.INFO)

@app.route("/proxy")
def proxy():
    # if random.random() < 0.2:
    #     time.sleep(3)
    #     return "", 504

    app.logger.info("Proxy endpoint called", extra={
        "path": request.path,
        "method": request.method,
        "client_ip": request.remote_addr
    })

    for handler in app.logger.handlers:
        handler.flush()
        
    return "OK"

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=9000)
