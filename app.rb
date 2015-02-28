#!/usr/bin/env ruby
require 'rubygems'
require 'sequel'
require 'nokogiri'
require 'zip'

puts 'Connecting to DB.'

Sequel.connect('oracle://oracle:welcome1@oracleserver:1521/orcl') { |db|
  puts 'Creating Models.'

  class SqUnitReport < Sequel::Model(:CSSDEMO__SQ_UNIT_REPORT)
    many_to_many :sqvalueattachment, left_key: :unitreport_id, right_key: :attachment_id, join_table: :sq_value_attachment_rel
  end

  class SqUnitReportCompressedFile < Sequel::Model(:CSSDEMO__SQ_UNIT_REPORT_COMPRESSED_FILE)
  end

  class SqValueAttachment < Sequel::Model(:CSSDEMO__SQ_VALUE_ATTACHMENT)
  end

  class SqValueAttachmentRel < Sequel::Model(:CSSDEMO__SQ_VALUE_ATTACHMENT_REL)
  end

  startrange = Date.strptime('2005/06/01', '%Y/%m/%d')
  endrange = Date.strptime('2005/06/03', '%Y/%m/%d')

  puts 'Searching reports.'

  reports = SqUnitReport.where(:starttime => (startrange)..(endrange)).limit(1000)

  file_names = reports.map(&:filename)

  puts 'Searching for files.'

  files = SqUnitReportCompressedFile.where(:filename => file_names)
  files_with_blobs = []
  files.each do |file|
    files_with_blobs << file if file.filedata != nil
  end

  puts "Files with blobs: #{files_with_blobs.count}"

  puts 'Writing files.'

  files_with_blobs.each do |file_with_blob|
    source = file_with_blob.filedata
    doc = Nokogiri::XML source
    File.open("./tmp/xml/#{file_with_blob.filename}", 'w') {|f| f.write(doc) }
  end

  puts 'XML files written.'

  puts 'Creating zip.'
  input_filenames = files_with_blobs.map(&:filename)

  zipfile_name = "#{startrange}-#{endrange}.zip"

  Zip::File.open(zipfile_name, Zip::File::CREATE) do |zipfile|
    input_filenames.each do |filename|
      zipfile.add(filename, './tmp/xml/' + filename)
    end
  end

  puts 'Done.'
}