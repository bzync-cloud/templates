import http from "node:http";

const port = Number(process.env.PORT ?? 3333);

http.createServer((req, res) => {
  res.setHeader("content-type", "application/json");
  if (req.url === "/health") {
    res.end(JSON.stringify({ status: "ok" }));
    return;
  }
  res.end(JSON.stringify({ message: "AdonisJS-style app running on Bzync Cloud" }));
}).listen(port, "0.0.0.0");
