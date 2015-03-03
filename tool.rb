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
end