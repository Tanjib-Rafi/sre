from flask import Flask, jsonify
import time
import random

app = Flask(__name__)

@app.route("/")
def home():
    # time.sleep(random.randint(3,8))
    return "Hello from SRE Test!"

@app.route("/healthz")
def health():
    # return jsonify({"status": "ok"}), 500
    return jsonify({"status": "ok"}), 200

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8080)
