require 'socket'

UDPSocket.new.send("<40> token[process]: hello world", 0, "localhost", 5000)
