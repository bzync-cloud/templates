require "dotenv/load"
require "webrick"
require "json"

interval = Integer(ENV.fetch("WORKER_INTERVAL_MS", "30000")) / 1000.0
status_port = Integer(ENV.fetch("STATUS_PORT", "3000"))

last_run = Time.now

# Reports whether the worker loop is still ticking, not just whether the
# process is running (Bzync Cloud's compute already checks that
# separately via container state + crash-loop detection) — same
# reachable/unreachable JSON convention as the redis/garage/seaweedfs
# templates' status sidecar.
stale_after = (interval * 2) + 30

status_server = WEBrick::HTTPServer.new(Port: status_port, Logger: WEBrick::Log.new(File::NULL), AccessLog: [])
status_server.mount_proc "/" do |_req, res|
  stale = (Time.now - last_run) > stale_after
  res.status = stale ? 503 : 200
  res["Content-Type"] = "application/json"
  res.body = {
    status: stale ? "error" : "ok",
    service: "worker",
    worker: stale ? "unreachable" : "reachable",
  }.to_json
end
Thread.new { status_server.start }

puts "Ruby worker heartbeat #{Time.now.utc.iso8601}"
$stdout.flush

loop do
  sleep interval
  puts "Ruby worker heartbeat #{Time.now.utc.iso8601}"
  $stdout.flush
  last_run = Time.now
end
