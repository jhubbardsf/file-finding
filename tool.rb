module Tool

  def get_file_name(full_address)
    full_address.gsub!('\\', '/')
    File.basename(full_address)
  end

  def get_reports (startdate, enddate)
    startrange = Date.strptime(startdate, '%Y/%m/%d')
    endrange = Date.strptime(enddate, '%Y/%m/%d')

    puts 'Searching reports.'

    SqUnitReport.where(:starttime => (startrange)..(endrange))
  end

  def files_from_names (file_names)
    files = []
    file_names.each_slice(1000) { | search_names|
      file_array = SqUnitReportCompressedFile.where(:filename => search_names)
      file_array.each do |file|
        files << file
      end
    }
    files
  end

  def save_attachments(file)
    file.attachment_ref.each do |attachment_ref|
      puts attachment_ref.attachment_id.to_i
      attachment = SqValueAttachment.where(:attachment_id => "#{attachment_ref.attachment_id}").first
      puts attachment.class.name
      path_name = attachment.fqn
      file_name = Tool.get_file_name(path_name)

      if (attachment.value_binary != nil)
        data = attachment.value_binary
      elsif (attachment.value_string != nil)
        data = attachment.value_string
        data.gsub!("\u2028", "\r\n")
      end

      File.open('./tmp/' + file_name, 'w') { |f| f.write(data) }
    end
  end

  def save_files_and_attachments(files)
    i = true
    files.each do |file|
      #Save initial XML file.
      source = file.filedata
      doc = Nokogiri::XML source
      File.open("./tmp/#{file.filename}", 'w') { |f| f.write(doc) }

      # Save attachments if any.
      if file.has_attachment?
        puts file.has_attachment?
        puts file.number_of_attachments
        save_attachments(file)
      end

      # ZIP everything up.
      zip_files('./tmp/', "./output/#{file.saving_dir}/#{file.filename}.zip")

      # Delete temp
      FileUtils.rm_rf("./tmp/.", secure: true)

      if (i == true)
        break
      end
    end
  end

  def zip_files(input_dir, output_filename)

  end
end

