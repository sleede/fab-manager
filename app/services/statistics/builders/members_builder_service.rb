# frozen_string_literal: true

# Generate statistics indicators about members
class Statistics::Builders::MembersBuilderService
  include Statistics::Concerns::HelpersConcern

  class << self
    def build(options = default_options)
      # account list
      Statistics::FetcherService.members_list(options).each do |m|
        Stats::Account.create({ date: format_date(m[:date]),
                                type: 'member',
                                subType: 'created',
                                stat: 1 }.merge(user_info_stat(m)))
      end

      # member ca list
      Statistics::FetcherService.members_ca_list(options).each do |m|
        Stats::User.create({ date: format_date(m[:date]),
                             type: 'revenue',
                             subType: m[:group],
                             stat: m[:ca] }.merge(user_info_stat(m)))
      end
    end
  end
end
