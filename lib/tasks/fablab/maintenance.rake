# frozen_string_literal: true

# Maintenance tasks
namespace :fablab do
  namespace :maintenance do
    desc 'Regenerate the invoices (invoices & avoirs) PDF'
    task :regenerate_invoices, %i[year month end] => :environment do |_task, args|
      start_date, end_date = dates_from_args(args)
      puts "-> Start regenerate the invoices PDF between #{I18n.l start_date, format: :long} and " \
           "#{I18n.l end_date - 1.minute, format: :long}"
      invoices = Invoice.where('created_at >= :start_date AND created_at < :end_date', start_date: start_date, end_date: end_date)
                        .order(created_at: :asc)
      invoices.each(&:regenerate_invoice_pdf)
      puts '-> Done'
    end

    task :regenerate_schedules, %i[year month end] => :environment do |_task, args|
      start_date, end_date = dates_from_args(args)
      puts "-> Start regenerate the payment schedules PDF between #{I18n.l start_date, format: :long} and " \
           "#{I18n.l end_date - 1.minute, format: :long}"
      schedules = PaymentSchedule.where('created_at >= :start_date AND created_at < :end_date', start_date: start_date, end_date: end_date)
                                 .order(created_at: :asc)
      schedules.each(&:regenerate_pdf)
      puts '-> Done'
    end

    desc 'recreate every versions of images'
    task build_images_versions: :environment do
      Project.find_each do |project|
        project.project_image.attachment.recreate_versions! if project.project_image.present? && project.project_image.attachment.present?
      end
      ProjectStepImage.find_each do |project_step_image|
        project_step_image.attachment.recreate_versions! if project_step_image.present? && project_step_image.attachment.present?
      end
      Machine.find_each do |machine|
        machine.machine_image.attachment.recreate_versions! if machine.machine_image.present?
      end
      Event.find_each do |event|
        event.event_image.attachment.recreate_versions! if event.event_image.present?
      end
    end

    desc 'generate current code checksum'
    task checksum: :environment do
      require 'integrity/checksum'
      puts Integrity::Checksum.code
    end

    desc 'delete users with accounts marked with is_active=false'
    task delete_inactive_users: :environment do
      count = User.where(is_active: false).count
      if count.positive?
        print "WARNING: You are about to delete #{count} users. Are you sure? (y/n) "
        confirm = $stdin.gets.chomp
        next unless confirm == 'y'

        User.where(is_active: false).map(&:destroy!)
      else
        puts 'No inactive users to delete'
      end
    end

    desc '(re)build customization stylesheet'
    task rebuild_stylesheet: :environment do
      Stylesheet.build_theme!
    end

    desc 'migration notifications from Fab-manager v1'
    task migrate_v1_notifications: :environment do
      Notification.where(notification_type_id: 4).each do |n|
        n.notification_type_id = 11
        n.save!
      end
    end

    desc 'get the version'
    task version: :environment do
      require 'version'
      puts Version.current
    end

    desc 'clean the cron workers'
    task clean_workers: :environment do
      Sidekiq::Cron::Job.destroy_all!
      Sidekiq::Queue.new('system').clear
      Sidekiq::Queue.new('default').clear
      Sidekiq::DeadSet.new.clear
    end

    desc 'save the footprint original data'
    task save_footprint_data: :environment do
      [Invoice, InvoiceItem, HistoryValue, PaymentSchedule, PaymentScheduleItem, PaymentScheduleObject].each do |klass|
        next if klass == PaymentScheduleObject && !ActiveRecord::Base.connection.table_exists?(PaymentScheduleObject.arel_table)

        order = klass == HistoryValue ? :created_at : :id
        previous = nil
        klass.order(order).find_each do |item|
          created = ChainedElement.create!(
            element: item,
            previous: previous
          )
          previous = created
        end
      end
    end

    desc 'regenerate statistics'
    task :regenerate_statistics, %i[year month] => :environment do |_task, args|
      exit unless Setting.get('statistics_module')

      yesterday = 1.day.ago
      year = args.year || yesterday.year
      month = args.month || yesterday.month
      start_date = Time.zone.local(year.to_i, month.to_i, 1)
      end_date = yesterday.end_of_day
      puts "-> Start regenerate statistics between #{I18n.l start_date, format: :long} and " \
           "#{I18n.l end_date, format: :long}"
      Statistics::BuilderService.generate_statistic(
        start_date: start_date,
        end_date: end_date
      )
      puts '-> Done'
    end

    desc 'Regenerate the invoices (invoices & avoirs) reference'
    task :regenerate_invoices_reference, %i[year month end] => :environment do |_task, args|
      start_date, end_date = dates_from_args(args)
      puts "-> Start regenerate the invoices reference between #{I18n.l start_date, format: :long} and " \
           "#{I18n.l end_date - 1.minute, format: :long}"
      invoices = Invoice.where('created_at >= :start_date AND created_at < :end_date', start_date: start_date, end_date: end_date)
                        .order(created_at: :asc)
      invoices.each(&:update_reference)
      puts '-> Done'
    end

    desc 'Regenerate accounting lines'
    task :regenerate_accounting_lines, %i[year month end] => :environment do |_task, args|
      start_date, end_date = dates_from_args(args)
      puts "-> Start regenerate the accounting lines between #{I18n.l start_date, format: :long} and " \
           "#{I18n.l end_date - 1.minute, format: :long}"
      AccountingLine.where(date: start_date.beginning_of_day..end_date.end_of_day).delete_all
      Accounting::AccountingService.new.build(start_date.beginning_of_day, end_date.end_of_day)
      puts '-> Done'
    end

    desc 'Remove ghost availabilities and slots'
    task clean_availabilities: :environment do
      Availability.where(available_type: 'unknown').destroy_all
    end

    def dates_from_args(args)
      year = args.year || Time.current.year
      month = args.month || Time.current.month
      start_date = Time.zone.local(year.to_i, month.to_i, 1)
      end_date = args.end == 'today' ? Time.current.end_of_day : start_date.next_month
      [start_date, end_date]
    end
  end
end
