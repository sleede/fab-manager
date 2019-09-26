# frozen_string_literal: true

# Provides helper methods to bulk-import some users from a CSV file
class Members::ImportService
  class << self
    def import(import)
      require 'csv'
      log = []
      CSV.foreach(import.attachment.url, headers: true, col_sep: ';') do |row|
        begin
          log << { row: row.to_hash }

          # try to find member based on import.update_field
          user = User.find_by(import.update_field.to_sym => row[import.update_field])
          params = row_to_params(row, user)
          if user
            service = Members::MembersService.new(user)
            res = service.update(params)
            log << { user: user.id, status: 'update', result: res }
          else
            user = User.new(params)
            service = Members::MembersService.new(user)
            res = service.create(import.user, params)
            log << { user: nil, status: 'create', result: res }
          end
          log << user.errors.to_hash unless user.errors.to_hash.empty?
        rescue StandardError => e
          log << e.to_s
          puts e
          puts e.backtrace
        end
      end
      log
    end

    private

    def row_to_params(row, user)
      res = {
        id: row['id'],
        username: row['username'],
        email: row['email'],
        password: row['password'],
        password_confirmation: row['password'],
        is_allow_contact: row['allow_contact'] == 'yes',
        is_allow_newsletter: row['allow_newsletter'] == 'yes',
        group_id: group_id(row),
        tag_ids: tag_ids(row)
      }

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
      res = {
        first_name: row['first_name'],
        last_name: row['last_name'],
        phone: row['phone'],
        interest: row['interests'],
        software_mastered: row['softwares'],
        website: row['website'],
        job: row['job'],
        facebook: row['facebook'],
        twitter: row['twitter'],
        google_plus: row['googleplus'],
        viadeo: row['viadeo'],
        linkedin: row['linkedin'],
        instagram: row['instagram'],
        youtube: row['youtube'],
        vimeo: row['vimeo'],
        dailymotion: row['dailymotion'],
        github: row['github'],
        echosciences: row['echosciences'],
        pinterest: row['pinterest'],
        lastfm: row['lastfm'],
        flickr: row['flickr']
      }

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
      res = {
        gender: row['gender'] == 'male',
        birthday: row['birthdate']
      }

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

      res = {
        name: row['organization_name']
      }

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
  end
end
