module Tool

  def get_file_name(full_address)
    full_address.gsub!('\\', '/')
    File.basename(full_address)
  end

  def get_reports (startdate, enddate)
    startrange = Date.strptime(startdate, '%Y/%m/%d')
    endrange = Date.strptime(enddate, '%Y/%m/%d')

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


  def save_files_and_attachments(files)
    files.each do |file|
      #Save initial XML file.
      source = file.filedata
      doc = Nokogiri::XML source
      File.open("./tmp/#{file.filename}", 'w') { |f| f.write(doc) }

      # Save attachments if any.
      if file.has_attachment?
        save_attachments(file)
      end

      dir = file.saving_dir

      # Make directory
      FileUtils::mkdir_p "./output/#{dir}"

      # ZIP everything up.
      zf = ZipFileGenerator.new('./tmp/', "./output/#{dir}/#{file.filename}.zip")
      zf.write()

      # Delete temp
      FileUtils.rm_rf(Dir.glob('./tmp/*'))
    end

    files.size
  end

  def save_attachments(file)
    file.attachment_ref.each do |attachment_ref|
      attachment = SqValueAttachment.where(:attachment_id => "#{attachment_ref.attachment_id}").first
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

  def valid_date?(date)
    y, m, d = date.split '/'
    Date.valid_date? y.to_i, m.to_i, d.to_i
  end
end

