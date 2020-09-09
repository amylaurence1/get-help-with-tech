class GsuiteDomainValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    if value.blank? || !Gsuite.is_gsuite_domain?(value)
      record.errors[attribute] << (options[:message] || 'is not a valid G Suite domain')
    end
  end
end
