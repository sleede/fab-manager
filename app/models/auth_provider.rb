class AuthProvider < ActiveRecord::Base

  # this is a simple stub used for database creation & configuration
  class SimpleAuthProvider < Object
    def providable_type
      DatabaseProvider.name
    end

    def name
      'DatabaseProvider::SimpleAuthProvider'
    end
  end

  PROVIDABLE_TYPES = %w(DatabaseProvider OAuth2Provider)

  belongs_to :providable, :polymorphic => true, dependent: :destroy
  accepts_nested_attributes_for :providable
  attr_accessible :name, :providable_type, :providable_attributes

  before_create :set_initial_state

  def build_providable(params, assignment_options)
    raise "Unknown providable_type: #{providable_type}" unless PROVIDABLE_TYPES.include?(providable_type)
    self.providable = providable_type.constantize.new(params)
  end

  ## Return the currently active provider
  def self.active
    local = SimpleAuthProvider.new

    begin
      provider = find_by(status: 'active')
      if provider.nil?
        return local
      else
        return provider
      end
    rescue ActiveRecord::StatementInvalid
      # we fall here on database creation because the table "active_providers" still does not exists at the moment
      return local
    end
  end

  ## Get the provider matching the omniAuth strategy name
  def self.from_strategy_name(strategy_name)
    if strategy_name.blank? or all.empty?
      return SimpleAuthProvider.new
    end
    parsed = /^([^-]+)-(.+)$/.match(strategy_name)
    ret = nil
    all.each do |strategy|
      if strategy.provider_type == parsed[1] and strategy.name.downcase.parameterize == parsed[2]
        ret = strategy
        break
      end
    end
    ret
  end

  ## Return the name that should be registered in OmniAuth for the corresponding strategy
  def strategy_name
    provider_type+'-'+name.downcase.parameterize
  end

  ## Return the provider type name without the "Provider" part.
  ## eg. DatabaseProvider will return 'database'
  def provider_type
    providable.class.name[0..-9].downcase
  end

  ## Return the user's profile fields that are currently managed from the SSO
  ## @return [Array]
  def sso_fields
    providable.protected_fields
  end

  ## Return the link the user have to follow to edit his profile on the SSO
  ## @return [String]
  def link_to_sso_profile
    providable.profile_url
  end

  def safe_destroy
    if self.status != 'active'
      destroy
    else
      false
    end
  end

  private
  def set_initial_state
    # the initial state of a new AuthProvider will be 'pending', except if there is currently
    # no providers in the database, he we will be 'active' (see seeds.rb)
    self.status = 'pending' unless AuthProvider.count == 0
  end
end
