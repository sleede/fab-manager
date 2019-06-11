# frozen_string_literal: true

# Maintenance tasks
namespace :fablab do
  namespace :maintenance do
    desc 'Regenerate the invoices PDF'
    task :regenerate_invoices, %i[year month] => :environment do |_task, args|
      year = args.year || Time.now.year
      month = args.month || Time.now.month
      start_date = Time.new(year.to_i, month.to_i, 1)
      end_date = start_date.next_month
      puts "-> Start regenerate the invoices PDF between #{I18n.l start_date, format: :long} and " \
         "#{I18n.l end_date - 1.minute, format: :long}"
      invoices = Invoice.only_invoice
                        .where('created_at >= :start_date AND created_at < :end_date', start_date: start_date, end_date: end_date)
                        .order(created_at: :asc)
      invoices.each(&:regenerate_invoice_pdf)
      puts '-> Done'
    end

    desc 'recreate every versions of images'
    task build_images_versions: :environment do
      Project.find_each do |project|
        if project.project_image.present? && project.project_image.attachment.present?
          project.project_image.attachment.recreate_versions!
        end
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

    desc 'generate fixtures from db'
    task generate_fixtures: :environment do
      Rails.application.eager_load!
      ActiveRecord::Base.descendants.reject { |c| [ActiveRecord::SchemaMigration, PartnerPlan].include? c }.each do |ar_base|
        p "========== #{ar_base} =============="
        ar_base.dump_fixtures
      end
    end

    desc 'generate current code checksum'
    task checksum: :environment do
      require 'checksum'
      puts Checksum.code
    end
  end
end
