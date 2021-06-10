# frozen_string_literal: true

namespace :fablab do
  namespace :setup do
    desc 'assign environment value to all invoices'
    task set_environment_to_invoices: :environment do
      Invoice.all.each do |i|
        i.environment = Rails.env
        i.save!
      end
    end

    desc 'add missing VAT rate to history'
    task :add_vat_rate, %i[rate date] => :environment do |_task, args|
      raise 'Missing argument. Usage exemple: rails fablab:setup:add_vat_rate[20,2014-01-01]. Use 0 to disable' unless args.rate && args.date

      if args.rate == '0'
        setting = Setting.find_by(name: 'invoice_VAT-active')
        HistoryValue.create!(
          setting_id: setting.id,
          user_id: User.admins.first.id,
          value: 'false',
          created_at: DateTime.parse(args.date)
        )
      else
        setting = Setting.find_by(name: 'invoice_VAT-rate')
        HistoryValue.create!(
          setting_id: setting.id,
          user_id: User.admins.first.id,
          value: args.rate,
          created_at: DateTime.parse(args.date)
        )
      end
    end

    desc 'migrate PDF invoices to folders numbered by invoicing_profile'
    task migrate_pdf_invoices_folders: :environment do
      puts 'No invoices, exiting...' and return if Invoice.count.zero?

      require 'fileutils'
      Invoice.all.each do |i|
        invoicing_profile = i.invoicing_profile
        user_id = invoicing_profile.user_id

        src = "invoices/#{user_id}/#{i.filename}"
        dest = "tmp/invoices/#{invoicing_profile.id}"

        if FileTest.exist?(src)
          FileUtils.mkdir_p dest
          FileUtils.mv src, "#{dest}/#{i.filename}", force: true
        end
      end
      FileUtils.rm_rf 'invoices'
      FileUtils.mv 'tmp/invoices', 'invoices'
    end

    desc 'add model for payment-schedules reference'
    task add_schedule_reference: :environment do
      setting = Setting.find_by(name: 'invoice_reference')
      current = setting.value
      setting.value = "#{current}S[/E]" unless /S\[([^\]]+)\]/.match?(current)
    end

    desc 'migrate environment variables to the database (settings)'
    task env_to_db: :environment do
      include ApplicationHelper

      mapping = [
        %w[_ PHONE_REQUIRED phone_required],
        %w[_ GA_ID tracking_id],
        %w[_ BOOK_SLOT_AT_SAME_TIME book_overlapping_slots],
        %w[_ SLOT_DURATION slot_duration],
        %w[_ EVENTS_IN_CALENDAR events_in_calendar],
        %w[! FABLAB_WITHOUT_SPACES spaces_module],
        %w[! FABLAB_WITHOUT_PLANS plans_module],
        %w[! FABLAB_WITHOUT_INVOICES invoicing_module],
        %w[_ FACEBOOK_APP_ID facebook_app_id],
        %w[_ TWITTER_NAME twitter_analytics],
        %w[_ RECAPTCHA_SITE_KEY recaptcha_site_key],
        %w[_ RECAPTCHA_SECRET_KEY recaptcha_secret_key],
        %w[_ FEATURE_TOUR_DISPLAY feature_tour_display],
        %w[_ DEFAULT_MAIL_FROM email_from],
        %w[_ DISQUS_SHORTNAME disqus_shortname],
        %w[_ ALLOWED_EXTENSIONS allowed_cad_extensions],
        %w[_ ALLOWED_MIME_TYPES allowed_cad_mime_types],
        %w[_ OPENLAB_APP_ID openlab_app_id],
        %w[_ OPENLAB_APP_SECRET openlab_app_secret],
        %w[_ OPENLAB_DEFAULT openlab_default],
        %w[! FABLAB_WITHOUT_ONLINE_PAYMENT online_payment_module],
        %w[_ STRIPE_PUBLISHABLE_KEY stripe_public_key],
        %w[_ STRIPE_API_KEY stripe_secret_key],
        %w[_ STRIPE_CURRENCY stripe_currency],
        %w[_ INVOICE_PREFIX invoice_prefix FabManager_invoice],
        %w[_ USER_CONFIRMATION_NEEDED_TO_SIGN_IN confirmation_required],
        %w[! FABLAB_WITHOUT_WALLET wallet_module],
        %w[! FABLAB_WITHOUT_STATISTICS statistics_module]
      ]

      mapping.each do |m|
        setting = Setting.find_or_initialize_by(name: m[2])
        value = ENV.fetch(m[1], m[3])
        next unless value

        # if the array starts with a "!", invert the boolean value
        value = (!str_to_bool(value)).to_s if m[0] == '!'
        setting.value = value
        setting.save
      end
    end
  end
end
