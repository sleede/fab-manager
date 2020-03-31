# frozen_string_literal: true

# Provides helper methods to bulk-import some users from a CSV file
class Members::ImportService
  class << self
    def import(import)
      require 'csv'
      log = []
      begin
      CSV.foreach(import.attachment.url, headers: true, col_sep: ';') do |row|
        begin
          password = hide_password(row)
          log << { row: row.to_hash }

          # try to find member based on import.update_field
          user = User.find_by(import.update_field.to_sym => row[import.update_field])
          params = row_to_params(row, user, password)
          if user
            service = Members::MembersService.new(user)
            res = service.update(params)
            log << { user: user.id, status: 'update', result: res }
          else
            user = User.new(params)
            service = Members::MembersService.new(user)
            res = service.create(import.user, params)
            log << { user: user.id, status: 'create', result: res }
          end
          log << user.errors.to_hash unless user.errors.to_hash.empty?
        rescue StandardError => e
          log << e.to_s
          puts e
          puts e.backtrace
        end
      end
      rescue ArgumentError => e
        log << e.to_s
        puts e
        puts e.backtrace
      end
      log
    end

    private

    def hashify(row, property, value: row[property], key: property.to_sym)
      res = {}
      res[key] = value if row[property]
      res
    end

    def row_to_params(row, user, password)
      res = {}

      res.merge! hashify(row, 'id')
      res.merge! hashify(row, 'username')
      res.merge! hashify(row, 'email')
      res.merge! hashify(row, 'password', value: password)
      res.merge! hashify(row, 'password', key: :password_confirmation, value: password)
      res.merge! hashify(row, 'allow_contact', value: row['allow_contact'] == 'yes', key: :is_allow_contact)
      res.merge! hashify(row, 'allow_newsletter', value: row['allow_newsletter'] == 'yes', key: :is_allow_newsletter)
      res.merge! hashify(row, 'group', value: group_id(row), key: :group_id)
      res.merge! hashify(row, 'tags', value: tag_ids(row), key: :tag_ids)

      profile_attributes = profile(row, user)
      res[:profile_attributes] = profile_attributes if profile_attributes

      invoicing_profile_attributes = invoicing_profile(row, user)
      res[:invoicing_profile_attributes] = invoicing_profile_attributes if invoicing_profile_attributes

      statistic_profile_attributes = statistic_profile(row, user)
      res[:statistic_profile_attributes] = statistic_profile_attributes if statistic_profile_attributes

      res
    end

    def group_id(row)
      return unless row['group']

      Group.friendly.find(row['group'])&.id
    end

    def tag_ids(row)
      return unless row['tags']

      Tag.where(id: row['tags'].split(',')).map(&:id)
    end

    def profile(row, user)
      res = {}

      res.merge! hashify(row, 'first_name')
      res.merge! hashify(row, 'last_name')
      res.merge! hashify(row, 'phone')
      res.merge! hashify(row, 'interests', key: :interest)
      res.merge! hashify(row, 'softwares', key: :software_mastered)
      res.merge! hashify(row, 'website')
      res.merge! hashify(row, 'job')
      res.merge! hashify(row, 'facebook')
      res.merge! hashify(row, 'twitter')
      res.merge! hashify(row, 'googleplus', key: :google_plus)
      res.merge! hashify(row, 'viadeo')
      res.merge! hashify(row, 'linkedin')
      res.merge! hashify(row, 'instagram')
      res.merge! hashify(row, 'youtube')
      res.merge! hashify(row, 'vimeo')
      res.merge! hashify(row, 'dailymotion')
      res.merge! hashify(row, 'github')
      res.merge! hashify(row, 'echosciences')
      res.merge! hashify(row, 'pinterest')
      res.merge! hashify(row, 'lastfm')
      res.merge! hashify(row, 'flickr')

      res[:id] = user.profile.id if user&.profile

      res
    end

    def invoicing_profile(row, user)
      res = {}

      res[:id] = user.invoicing_profile.id if user&.invoicing_profile

      address_attributes = address(row, user)
      res[:address_attributes] = address_attributes if address_attributes

      organization_attributes = organization(row, user)
      res[:organization_attributes] = organization_attributes if organization_attributes

      res
    end

    def statistic_profile(row, user)
      res = {}

      res.merge! hashify(row, 'gender', value: row['gender'] == 'male')
      res.merge! hashify(row, 'birthdate', key: :birthday)

      res[:id] = user.statistic_profile.id if user&.statistic_profile

      training_ids = training_ids(row)
      res[:training_ids] = training_ids if training_ids

      res
    end

    def address(row, user)
      return unless row['address']

      res = { address: row['address'] }

      res[:id] = user.invoicing_profile.address.id if user&.invoicing_profile&.address

      res
    end

    def organization(row, user)
      return unless row['organization_name']

      res = { name: row['organization_name'] }

      res[:id] = user.invoicing_profile.organization.id if user&.invoicing_profile&.organization

      address_attributes = organization_address(row, user)
      res[:address_attributes] = address_attributes if address_attributes

      res
    end

    def organization_address(row, user)
      return unless row['organization_address']

      res = { address: row['organization_address'] }

      res[:id] = user.invoicing_profile.organization.address.id if user&.invoicing_profile&.organization&.address

      res
    end

    def training_ids(row)
      return unless row['trainings']

      Training.where(id: row['trainings'].split(',')).map(&:id)
    end

    def hide_password(row)
      password = row['password']
      row['password'] = '********' if row['password']
      password
    end
  end
end
