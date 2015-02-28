#!/usr/bin/env ruby
require 'rubygems'
require 'sequel'

puts 'Connecting to DB.'

DB = Sequel.connect('oracle://oracle:welcome1@oracleserver:1521/orcl')

puts 'Creating Models.'

class SqUnitReport < Sequel::Model(:CSSDEMO__SQ_UNIT_REPORT)
end

class SqUnitReportCompressedFile < Sequel::Model(:CSSDEMO__SQ_UNIT_REPORT_COMPRESSED_FILE)
end

class SqValueAttachment < Sequel::Model(:CSSDEMO__SQ_VALUE_ATTACHMENT)
end

class SqValueAttachmentRel < Sequel::Model(:CSSDEMO__SQ_VALUE_ATTACHMENT_REL)
end

startrange = Date.strptime('2005-06-01', '%Y-%m-%d')
endrange = Date.strptime('2005-06-03', '%Y-%m-%d')

puts 'Searching reports.'

reports = SqUnitReport.where(:starttime => (startrange)..(endrange)).limit(1000)

file_names = reports.map(&:filename)

puts file_names.count

file_names[0..10].each do |file|
  puts file
end

puts 'Searching for files.'

files = SqUnitReportCompressedFile.where(:filename => file_names)
files_with_blobs = []
files.each do |file|
  files_with_blobs << file if file.filedata != nil
end

puts "Files with blobs: #{files_with_blobs.count}"