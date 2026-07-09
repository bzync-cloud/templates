const http = require('http');

const port = process.env.PORT || 3000;

const server = http.createServer((req, res) => {
  res.setHeader('Content-Type', 'application/json');
  if (req.url === '/health') {
    res.end(JSON.stringify({ status: 'ok' }));
  } else {
    res.end(JSON.stringify({ message: 'Welcome' }));
  }
});

server.listen(port, () => console.log(`Server running on port ${port}`));
