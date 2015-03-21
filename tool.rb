module Tools

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
    i = 0

    files.each do |file|
      dir = file.saving_dir
      file_tmp_dir = "./tmp/#{file.filename}"

      # Make tmp dir
      FileUtils.mkdir_p file_tmp_dir

      # Save initial XML file.
      source = file.filedata
      File.open("#{file_tmp_dir}/#{file.filename}.zip", 'wb') { |f| f.write(source) }

      # Unzip XML file
      begin
        Zip::File.open("#{file_tmp_dir}/#{file.filename}.zip") { |zip_file|
          zip_file.each { |f|
            f_path= File.join(file_tmp_dir, file.filename)
            FileUtils.mkdir_p(File.dirname(f_path))
            zip_file.extract(f, f_path) unless File.exist?(f_path)
          }
        }

        # Formats XML file
        current = File.open("#{file_tmp_dir}/#{file.filename}",'r').read
        File.open("#{file_tmp_dir}/#{file.filename}",'w') { |f| f.print Nokogiri::XML(current).to_xml  }

        while (!File.file?("./tmp/#{file.filename}/#{file.filename}")) do
          # Delete old zip file.
          File.delete("#{file_tmp_dir}/#{file.filename}.zip")
        end
      rescue
        # puts "Error with zip file: #{file_tmp_dir}/#{file.filename}.zip"
      end


      # Save attachments if any.
      if file.has_attachment?
        save_attachments(file)
      end

      # Make output directory
      FileUtils.mkdir_p "./output/#{dir}"

      # ZIP everything up.
      zf = ZipFileGenerator.new(file_tmp_dir, "./output/#{dir}/#{file.filename}.zip")
      zf.write_move_delete()
      print "#{i = i + 1} out of #{files.size} zip files written."
      print " (#{percent_of(i, files.size).round(2)}%)"
      print "\r"
    end

    files.size
  end

  def save_attachments(file)
    file.attachment_ref.each do |attachment_ref|
      attachment = SqValueAttachment.where(:attachment_id => "#{attachment_ref.attachment_id}").first
      path_name = attachment.fqn
      file_name = get_file_name(path_name)

      if (attachment.value_string != nil && !attachment.value_string.empty?)
        data = attachment.value_string
        data.gsub!("\u2028", "\r\n")
      elsif (attachment.value_binary != nil && !attachment.value_binary.empty?)
        data = attachment.value_binary
      end

      File.open("./tmp/#{file.filename}/" + file_name, 'wb') { |f| f.write(data) }
    end
  end

  def valid_date?(date)
    y, m, d = date.split '/'
    Date.valid_date? y.to_i, m.to_i, d.to_i
  end

  def percent_of(first, second)
    return 0 if second.to_i == 0
    (first.to_f / second.to_f) * 100
  end
end