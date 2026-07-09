require 'webrick'
require 'json'

server = WEBrick::HTTPServer.new(Port: 3000, BindAddress: '0.0.0.0')

server.mount_proc '/' do |req, res|
  res.content_type = 'application/json'
  res.body = case req.path
             when '/health' then { status: 'ok' }.to_json
             else { message: 'Welcome' }.to_json
             end
end

trap('INT') { server.shutdown }
server.start
