#!/usr/bin/env ruby
require 'rubygems'
require 'sequel'
require 'zip'
require 'fileutils'
require 'yaml'
require './tool.rb'
require './zip_file.rb'
include Tool

FileUtils.mkdir_p 'tmp'
s = YAML::load(File.open('./settings.yml'))

# Checks for both date arguments
unless (ARGV[0] && ARGV[1])
  puts 'Please enter dates.'
  puts 'Example:'
  puts './app.rb "2014/09/15" "2014/10/13"'
  abort
end

start_time = ARGV[0]
puts "Start time: #{start_time}"
end_time = ARGV[1]
puts "End time: #{end_time}"

# Checks if dates are valid
if (valid_date?(start_time) && valid_date?(end_time))
  puts 'Valid dates.'
else
  puts 'Invalid dates.'
  puts 'Application quitting.'
  puts 'Please use YYYY/MM/DD for the date formats.'
  puts 'Example:'
  puts './app.rb "2014/09/15" "2014/10/13"'
  abort
end

puts 'Connecting to DB.'
Sequel.connect("oracle://#{s[:username]}:#{s[:password]}@#{s[:server_address]}:#{s[:server_port]}/#{s[:server_schema]}") { |db|
  require './models.rb'

  puts 'Get reports by time range.'
  reports = get_reports(start_time, end_time)
  file_names = reports.map(&:filename)

  puts 'Searching for files.'
  files = files_from_names(file_names)

  puts 'Writing files.'
  total = save_files_and_attachments(files)

  puts "Total zip files made: #{total}"

  puts 'Done.'
}


