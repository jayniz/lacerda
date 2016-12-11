#encoding: utf-8
#!/usr/bin/env ruby

require 'bundler/gem_tasks'

require 'ffi'

task default: :compile

desc 'Compile drafter'
task :compile do
  prefix = FFI::Platform.mac? ? '' : 'lib.target/'
  # Path to compiled drafter library
  path = File.expand_path("ext/drafter/build/out/Release/#{prefix}libdrafter.#{FFI::Platform::LIBSUFFIX}", File.dirname(__FILE__))
  puts "Path to library #{path}"
  if !File.exist?(path) || ENV['RECOMPILE']
    puts 'The library does not exist, lets compile it'
    unless File.directory?(File.expand_path('ext/drafter/src'))
      puts 'Initializing submodules (if required)...'
      `git submodule update --init --recursive`
    end
    puts 'Compiling...'
    `cd #{File.expand_path('ext/drafter/')} && ./configure --shared && make drafter`
    status = $CHILD_STATUS.to_i
    if status == 0
      puts 'Compiling done.'
    else
      puts 'Compiling error, exiting.'
      next # If i'm using exit, abort I have some errors in rake install but gem can be installed
    end
  else
    puts 'Extension already compiled. To recompile set env variable RECOMPILE=true.'
  end
end

# Bundler.require
#$:.unshift File.join(File.dirname(__FILE__), "lib")

#require 'lacerda/tasks'
