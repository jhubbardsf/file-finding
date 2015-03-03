#!/usr/bin/env ruby
require 'rubygems'
require 'sequel'
require 'nokogiri'
require 'zip'
require './tool.rb'
include Tool

puts 'Connecting to DB.'

Sequel.connect('oracle://oracle:welcome1@oracleserver:1521/orcl') { |db|
  require './models.rb'

  start_time = '2005/06/01'
  end_time   = '2005/06/05'

  reports = get_reports(start_time, end_time)

  file_names = reports.map(&:filename)

  puts 'Searching for files.'

  files_with_blobs = []
  t = 0
  file_names.each_slice(1000) { | search_names|
    files = SqUnitReportCompressedFile.where(:filename => search_names)
    files.each do |file|
      t = t + 1
      files_with_blobs << file if file.filedata != nil
    end
  }

  puts "Files with blobs: #{files_with_blobs.count}"

  puts 'Writing files.'

  files_with_blobs.each do |file_with_blob|
    source = file_with_blob.filedata
    doc = Nokogiri::XML source
    # File.open("./tmp/xml/#{file_with_blob.filename}", 'w') { |f| f.write(doc) }
  end

  puts 'XML files written.'

  puts 'Creating zip.'
  input_filenames = files_with_blobs.map(&:filename)

  zipfile_name = "#{start_time.to_s.gsub('-', '.')}-#{end_time.to_s.gsub('-', '.')}.zip"

  # Zip::File.open(zipfile_name, Zip::File::CREATE) do |zipfile|
  #   input_filenames.each do |filename|
  #     zipfile.add(filename, './tmp/xml/' + filename)
  #   end
  # end

  puts 'Testing BLOB/CLOB Download'
  returns = SqValueAttachment.where("VALUE_BINARY IS NOT NULL OR VALUE_STRING IS NOT NULL")
  puts "Total returns: #{returns.count}"

  returns.each do |attachment|
    path_name = attachment.fqn
    file_name = Tool.get_file_name(path_name)

    if (attachment.value_binary != nil)
      data = attachment.value_binary
    elsif (attachment.value_string != nil)
      data = attachment.value_string
      data.gsub!("\u2028", "\r\n")
    end

    File.open('./' + file_name, 'w') { |f| f.write(data) }
  end

  puts 'Done.'
}


