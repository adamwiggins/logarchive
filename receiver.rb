require 'eventmachine'
require 'i18n'
require 'happening'

port = (ENV['PORT'] || 8000).to_i
puts "Starting on port #{port}"

$queue = ""

module LogReceiver
  def receive_data(data)
    puts "Got #{data.size} bytes: #{data}"
    $queue += data + "\n"
  end

  def self.archive
    puts "Archiving queue:\n#{$queue}"
    to_upload = $queue
    $queue = ""

    on_error = Proc.new { |http| puts "An error occured: #{http.response_header.status}" }

    bucket = ENV['S3_BUCKET']
    file = 'test.txt'

    item = Happening::S3::Item.new(bucket, file, :aws_access_key_id => ENV['AWS_ACCESS_KEY_ID'], :aws_secret_access_key => ENV['AWS_SECRET_ACCESS_KEY'])

    item.put(to_upload, :on_error => on_error) do |response|
      puts "Upload finished: http://s3.amazonaws.com/#{bucket}/#{file}"
    end
  end
end

EM.run do
  EM.open_datagram_socket('0.0.0.0', port, LogReceiver)

  EM.add_periodic_timer(5) do
    LogReceiver.archive
  end
end
