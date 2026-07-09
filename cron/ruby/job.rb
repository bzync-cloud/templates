require "dotenv/load"
require "rufus-scheduler"

interval = Integer(ENV.fetch("CRON_INTERVAL_SECONDS", "300"))

scheduler = Rufus::Scheduler.new

scheduler.every "#{interval}s", first_at: Time.now do
  puts "Ruby cron job ran #{Time.now.utc.iso8601}"
  $stdout.flush
end

puts "Ruby cron scheduled every #{interval}s"
$stdout.flush

scheduler.join
