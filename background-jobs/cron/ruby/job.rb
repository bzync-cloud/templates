require "dotenv/load"
require "rufus-scheduler"
require "webrick"
require "json"

interval = Integer(ENV.fetch("CRON_INTERVAL_SECONDS", "300"))
status_port = Integer(ENV.fetch("STATUS_PORT", "3000"))

last_run = Time.now

scheduler = Rufus::Scheduler.new

scheduler.every "#{interval}s", first_in: 0 do
  puts "Ruby cron job ran #{Time.now.utc.iso8601}"
  $stdout.flush
  last_run = Time.now
end

puts "Ruby cron scheduled every #{interval}s"
$stdout.flush

# Reports whether the scheduler is still ticking, not just whether the
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
    service: "cron",
    cron: stale ? "unreachable" : "reachable",
  }.to_json
end
Thread.new { status_server.start }

scheduler.join
