import json
from wsgiref.simple_server import make_server


def app(environ, start_response):
    path = environ.get("PATH_INFO", "/")
    if path == "/health":
        body = json.dumps({"status": "ok"}).encode()
    else:
        body = json.dumps({"message": "Welcome"}).encode()
    start_response("200 OK", [
        ("Content-Type", "application/json"),
        ("Content-Length", str(len(body))),
    ])
    return [body]


if __name__ == "__main__":
    server = make_server("0.0.0.0", 8000, app)
    server.serve_forever()
