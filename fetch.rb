require 'chronic'
require 'fileutils'

abort("Set TZ=UTC please") unless ENV['TZ'] == 'UTC'
abort("No S3_BUCKET specified") unless ENV['S3_BUCKET']

usage = "usage: #{$0} FROM TO\nexample: #{$0} '3 hours ago' now"
from_s = ARGV.shift or abort(usage)
to_s = ARGV.shift or abort(usage)

from = Chronic.parse(from_s) or abort("#{from_s} failed to parse")
to = Chronic.parse(to_s) or abort("#{to_s} failed to parse")

puts "Fetching #{from} until #{to} (#{((to - from) / 60).to_i} minutes)"

STDOUT.sync = true
print "["

$files = []

def cleanup
  $files.each { |f| FileUtils.rm(f) }
  puts
end

trap('INT') { cleanup }

cursor = from
while cursor < to
  t = cursor

  truncated_min = sprintf("%02d", (t.min / 10).to_i * 10)
  timerange = "#{t.year}-#{t.month}-#{t.day}-#{t.hour}:#{truncated_min}:00"
  file = "log-#{timerange}.txt"

  url = "http://s3.amazonaws.com/#{ENV['S3_BUCKET']}/#{file}"
  system "curl #{url} -o #{file} --silent --fail"
  unless $?.success? or $?.exitstatus == 22
    cleanup
    exit(1)
  end

  if File.exists?(file)
    $files << file
    print "="
  else
    print "_"
  end

  cursor = t + 10*60
end

if $files.empty?
  puts "No logs found for that period"
else
  puts "]"
  system "cat #{$files.join(' ')} > log.txt"
  $files.each { |f| FileUtils.rm(f) }
  puts "done, result is in log.txt"
end
