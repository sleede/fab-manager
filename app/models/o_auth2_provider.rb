class OAuth2Provider < ActiveRecord::Base
  has_one :auth_provider, as: :providable
  has_many :o_auth2_mappings, dependent: :destroy
  accepts_nested_attributes_for :o_auth2_mappings, allow_destroy: true

  def domain
    URI(base_url).scheme+'://'+URI(base_url).host
  end

  def protected_fields
    fields = []
    o_auth2_mappings.each do |mapping|
      fields.push(mapping.local_model+'.'+mapping.local_field)
    end
    fields
  end
end
