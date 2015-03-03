puts 'Creating models.'


class SqUnitReportCompressedFile < Sequel::Model(:CSSDEMO__SQ_UNIT_REPORT_COMPRESSED_FILE)
  set_primary_key [:id]

  one_to_many :attachment_ref, class: :SqValueAttachmentRel, key: :unitreport_id
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

  one_to_one :sq_value_attachment, key: :attachment_id
end
