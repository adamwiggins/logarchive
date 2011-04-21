require 'eventmachine'

port = (ENV['PORT'] || 8000).to_i
puts "Starting on port #{port}"

module LogReceiver
  def receive_data(data)
    puts "Got #{data.size} bytes: #{data}"
  end
end

EM.run do
  EM.open_datagram_socket('0.0.0.0', port, LogReceiver)
end
