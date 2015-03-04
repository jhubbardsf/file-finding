#!/usr/bin/env ruby
require 'rubygems'
require 'sequel'
require 'nokogiri'
require 'zip'
require './tool.rb'
require './zip_file.rb'
include Tool

puts 'Connecting to DB.'

Sequel.connect('oracle://oracle:welcome1@oracleserver:1521/orcl') { |db|
  require './models.rb'

  start_time = '2005/06/01'
  end_time   = '2005/06/05'

  reports = get_reports(start_time, end_time)

  file_names = reports.map(&:filename)

  puts 'Searching for files.'

  files = files_from_names (file_names)

  puts 'Writing files.'

  save_files_and_attachments(files)

  puts 'Done.'
}


