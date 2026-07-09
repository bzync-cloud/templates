require "dotenv/load"

interval = Integer(ENV.fetch("WORKER_INTERVAL_MS", "30000")) / 1000.0

puts "Ruby worker heartbeat #{Time.now.utc.iso8601}"
$stdout.flush

loop do
  sleep interval
  puts "Ruby worker heartbeat #{Time.now.utc.iso8601}"
  $stdout.flush
end
