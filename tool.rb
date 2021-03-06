module Tools
  def get_file_name(full_address)
    full_address.gsub!('\\', '/')
    File.basename(full_address)
  end

  def get_reports (startdate, enddate)
    startrange = Date.strptime(startdate, '%Y/%m/%d')
    endrange = Date.strptime(enddate, '%Y/%m/%d')

    SqUnitReport.where(:created_date => (startrange)..(endrange))
  end

  def files_from_names (file_names)
    files = []
    base = 0
    file_total = 0
    file_names.each_slice(1000) { | search_names |
      file_array = SqUnitReportCompressedFile.where(:filename => search_names)
      file_array.each do |file|
        files << file
      end
      puts files.size
      puts "Processing files #{base} - #{base + 1000}."
      base += 1000
      total = save_files_and_attachments(files)
      file_total += total
    }
    file_total
  end

  def save_files_and_attachments(files_original)
    i = 0
    total_count = files_original.size

    files_original.each_slice(100) do |files|
      files.each do |file|
        file_out_tree      = "//10.40.10.62/ExtractedFiles/Files/#{file.saving_dir}/"
        file_out_full_name = "#{file_out_tree}/#{file.filename}.zip"

        file_tmp_dir       = "//10.40.10.62/ExtractedFiles/Files/tmp/#{file.filename}/"
        file_tmp_zip       = "#{file_tmp_dir}/#{file.filename}.zip"
        file_tmp_full      = "#{file_tmp_dir}/#{file.filename}"

        # Make tmp dir
        FileUtils.mkdir_p file_tmp_dir

        # Save initial XML file.
        source = file.filedata
        File.open(file_tmp_zip, 'wb') { |f| f.write(source) }

        # Unzip XML file
        begin
          Zip::File.open(file_tmp_zip) { |zip_file|
            zip_file.each { |f|
              f_path = file_tmp_full
              FileUtils.mkdir_p(File.dirname(f_path))
              zip_file.extract(f, f_path) unless File.exist?(f_path)
            }
          }

          # Formats XML file
          current = File.read(file_tmp_zip)
          File.open(file_tmp_dir,'w') { |f| f.print Nokogiri::XML(current).to_xml  }


        rescue
          # puts "Error with zip file: #{file_tmp_dir}/#{file.filename}.zip"
        end

        # Delete zip
        File.delete(file_tmp_zip)

        # Save attachments if any.
        if file.has_attachment?
          save_attachments(file)
        end

        # Make output directory
        FileUtils.mkdir_p file_out_tree

        # ZIP everything up.
        zf = ZipFileGenerator.new(file_tmp_dir, file_out_full_name)
        zf.write_move_delete()
        print "#{i = i + 1} out of #{total_count} zip files written."
        print " (#{percent_of(i, total_count).round(2)}%)"
        print "\r"
      end
      FileUtils.remove_dir('//10.40.10.62/ExtractedFiles/Files/tmp/', force: true)
    end

    total_count
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

      File.open("//10.40.10.62/ExtractedFiles/Files/tmp/#{file.filename}/" + file_name, 'wb') { |f| f.write(data) }
      
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