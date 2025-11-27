from flask import Flask, request
import random
import time

app = Flask(__name__)

@app.route("/proxy")
def proxy():
    # if random.random() < 0.2:
    #     time.sleep(3)
    #     return "", 504
    return "OK"

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=9000)
