# frozen_string_literal: true

# Provides helper methods to bulk-import some users from a CSV file
class Members::ImportService
  class << self
    def import(import)
      require 'csv'
      CSV.foreach(import.attachment.url, headers: true, col_sep: ';') do |row|
        # try to find member based on import.update_field
        user = User.find_by(import.update_field.to_sym => import.update_field)
        if user
          service = Members::MembersService.new(user)
          service.update(row_to_params(row))
        else
          user = User.new(row)
          service = Members::MembersService.new(user)
          service.create(import.user, row_to_params(row))
        end
      end
    end

    private

    def row_to_params(row)
      {
        username: row['username'],
        email: row['email'],
        password: row['password'],
        password_confirmation: row['password'],
        is_allow_contact: row['allow_contact'],
        is_allow_newsletter: row['allow_newsletter'],
        group_id: Group.friendly.find(row['group'])&.id,
        tag_ids: Tag.where(id: row['tags'].split(',')).map(&:id),
        profile_attributes: profile_attributes(row),
        invoicing_profile_attributes: invoicing_profile_attributes(row),
        statistic_profile_attributes: statistic_profile_attributes(row)
      }
    end

    def profile_attributes(row)
      {
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
    end

    def invoicing_profile_attributes(row)
      {
        address_attributes: {
          address: row['address']
        },
        organization_attributes: {
          name: row['organization_name'],
          address_attributes: {
            address: row['organization_address']
          }
        }
      }
    end

    def statistic_profile_attributes(row)
      {
        gender: row['gender'] == 'male',
        birthday: row['birthdate'],
        training_ids: Training.where(id: row['trainings'].split(',')).map(&:id)
      }
    end
  end
end
