#!/usr/bin/env ruby

require 'rack'

loop do
  @webrick_pid = Process.fork do
    Rack::Server.start
  end

  IO.write("webrick.pid", @webrick_pid)
  Process.wait @webrick_pid
end
