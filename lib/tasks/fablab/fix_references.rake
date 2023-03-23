# frozen_string_literal: true

require 'integrity/archive_helper'

namespace :fablab do
  desc 'Fill the holes in the logical sequence of invoices references and regenerate invoices w/ duplicate reference'
  task fix_references: :environment do |_task, _args|
    include ActionView::Helpers::NumberHelper

    user = User.adminsys || User.admins.first

    # check the footprints
    Integrity::ArchiveHelper.check_footprints
    ActiveRecord::Base.transaction do
      missing_references = {}

      # browse invoices to list missing reference
      not_closed(Invoice).order(created_at: :desc).each do |invoice|
        number = Invoices::NumberService.number(invoice)
        next if number == 1

        previous = Invoices::NumberService.change_number(invoice, number - 1)
        next unless Invoice.find_by(reference: previous).nil?

        missing_references[invoice.created_at] ||= []
        missing_references[invoice.created_at].push(previous)
      end

      # create placeholder invoices for found missing references
      missing_references.each_pair do |date, references|
        references.reverse_each.with_index do |reference, index|
          Invoice.create!(
            total: 0,
            invoicing_profile: user.invoicing_profile,
            statistic_profile: user.statistic_profile,
            operator_profile: user.invoicing_profile,
            payment_method: '',
            reference: reference,
            created_at: date - (index + 1).seconds,
            description: 'Facture à néant, saut de facturation suite à un dysfonctionnement du logiciel Fab Manager',
            invoice_items_attributes: [{
              amount: 0,
              description: 'facture à zéro',
              object_type: 'Error',
              object_id: 1,
              main: true
            }]
          )
        end
      end

      # chain records
      puts 'Chaining all record. This may take a while...'
      not_closed(InvoiceItem).order(:id).find_each(&:chain_record)
      not_closed(Invoice).order(:id).find_each(&:chain_record)
    end
  end

  # @param klass [Class]
  # @return [ActiveRecord::Relation<klass>,Class]
  def not_closed(klass)
    if AccountingPeriod.count.positive?
      last_period = AccountingPeriod.order(start_at: :desc).first
      klass.where('created_at > ?', last_period.end_at)
    else
      klass
    end
  end
end
