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
          created_at: Time.zone.parse(args.date)
        )
      else
        setting = Setting.find_by(name: 'invoice_VAT-rate')
        HistoryValue.create!(
          setting_id: setting.id,
          user_id: User.admins.first.id,
          value: args.rate,
          created_at: Time.zone.parse(args.date)
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

    desc 'migrate administrators to normal groups and validate them'
    task set_admins_group: :environment do
      groups = Group.where.not(slug: 'admins').where(disabled: [false, nil]).order(:id)
      User.admins.each do |admin|
        print "\e[91m::\e[0m \e[1mMove admin #{admin.profile} to group\e[0m:\n"
        admin.update(group_id: select_group(groups))
        PaymentGatewayService.new.create_user(admin.id)
      end
      print "\e[91m::\e[0m \e[1mRemoving the 'admins' group...\e[0m\n"
      Group.find_by(slug: 'admins').destroy
      if Setting.get('user_validation_required')
        print "\e[91m::\e[0m \e[1mValidating the 'admins'...\e[0m\n"
        User.admins.each { |admin| admin.update(validated_at: Time.current) if admin.validated_at.nil? }
      end
      print "\e[32m✅\e[0m \e[1mDone\e[0m\n"
    end

    desc 'generate acconting lines'
    task build_accounting_lines: :environment do
      start_date = Invoice.order(created_at: :asc).first&.created_at || Time.current
      end_date = Time.current
      AccountingLine.where(date: start_date..end_date).destroy_all
      Accounting::AccountingService.new.build(start_date&.beginning_of_day, end_date.end_of_day)
      puts '-> Done'
    end

    desc 'build the reserved places cache for all slots'
    task build_places_cache: :environment do
      puts 'Builing the places cache. This may take some time...'
      total = Slot.maximum(:id)
      Slot.order(id: :asc).find_each do |slot|
        puts "#{slot.id} / #{total}"
        Slots::PlacesCacheService.refresh(slot)
      end
      puts '-> Done'
    end

    def select_group(groups)
      groups.each do |g|
        print "#{g.id}) #{g.name}\n"
      end
      print '> '
      group_id = $stdin.gets.chomp
      if groups.map(&:id).include?(group_id.to_i)
        group_id
      else
        warn "\e[91m[ ❌ ] Please select a valid group number \e[39m"
        select_group(groups)
      end
    end
  end
end
