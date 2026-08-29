from flask import Flask, jsonify
import os
import socket

app = Flask(__name__)

@app.route("/")
def index():
    return jsonify({
        "message": "Hello from the Mini DevOps Pipeline! Now automated via Jenkins CI/CD.",
        "hostname": socket.gethostname(),
        "env": os.environ.get("APP_ENV", "development"),
        "version": "1.5"
    })

@app.route("/health")
def health():
    return jsonify({"status": "ok"}), 200

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
