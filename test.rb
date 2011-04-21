require 'socket'

UDPSocket.new.send("<40> token[process]: hello world at #{Time.now}", 0, "localhost", 5000)
