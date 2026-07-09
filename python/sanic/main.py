import os
from sanic import Sanic
from sanic.response import json

app = Sanic("sanic_starter")


@app.get("/")
async def index(request):
    return json({"message": "Sanic API running on Bzync Cloud"})


@app.get("/health")
async def health(request):
    return json({"status": "ok"})


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=int(os.getenv("PORT", "8000")))
