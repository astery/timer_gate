# A sample Guardfile
# More info at https://github.com/guard/guard#readme

require 'rack'
require 'fileutils'

def webrick_pid
  IO.read("webrick.pid")
end

def restart_webrick
  out = system("kill -INT #{webrick_pid}")
  "Server restarted: #{out}"
end

guard :shell do
  watch(/.*\.rb$/) { restart_webrick }
  watch(/^config\.ru$/) { restart_webrick }
  watch(/^Gemfile$/) { restart_webrick }
end
