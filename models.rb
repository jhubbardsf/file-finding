puts 'Creating models.'

class SqUnitReportCompressedFile < Sequel::Model(:CSSDEMO__SQ_UNIT_REPORT_COMPRESSED_FILE)
  set_primary_key [:id]

  one_to_many :attachment_ref, class: :SqValueAttachmentRel, key: :unitreport_id
  one_to_one :sq_unit, class: :SqUnitReport, key: :id

  def has_attachment?
    number_of_attachments > 0
  end

  def number_of_attachments
    self.attachment_ref.size
  end

  def attachments
    attachments = []
    self.attachment_ref.each do |ref|
      attachments << ref.attachment
    end
    attachments
  end

  def saving_dir
    time = sq_unit.starttime.strftime('%Y/%m/%d')
  end
end

class SqUnitReport < Sequel::Model(:CSSDEMO__SQ_UNIT_REPORT)
  set_primary_key [:id]

  one_to_one :compressed_file, class: SqUnitReportCompressedFile, key: :id
end

class SqValueAttachment < Sequel::Model(:CSSDEMO__SQ_VALUE_ATTACHMENT)
  set_primary_key [:id]

end

class SqValueAttachmentRel < Sequel::Model(:CSSDEMO__SQ_VALUE_ATTACHMENT_REL)
  set_primary_key [:id]

  one_to_one :attachment, class: :SqValueAttachment, key: :attachment_id
end
