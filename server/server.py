from sanic import Sanic, Request, HTTPResponse, json as jsonResponse, file
from sanic_ext import validate
from dataclasses import dataclass
import json

app = Sanic("Chat")

@app.get("/")
async def homepage(request: Request) -> HTTPResponse:
    return await file("index.html")

@dataclass
class SendMessageRequest:
    message: str
    author: str

@app.post("/send")
@validate(json=SendMessageRequest)
async def send(request: Request, body: SendMessageRequest) -> HTTPResponse:
    with open("messages.json", "r") as f:
        messages = json.load(f)

    messages.append({
        "message": body.message,
        "author": body.author
    })

    with open("messages.json", "w") as f:
        json.dump(messages, f, indent=4)

    return jsonResponse({})

@app.get("/messages")
async def get_messages(request: Request) -> HTTPResponse:
    with open("messages.json", "r") as f:
        messages = json.load(f)

    return jsonResponse(messages)

app.static("static/", "./static/")

if __name__ == "__main__":
    app.run(host = "localhost", port=8000)
