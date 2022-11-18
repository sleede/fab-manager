# frozen_string_literal: false

# module definition
module Accounting; end

# fetch the code matching the given resource
class Accounting::AccountingCodeService
  class << self
    def client_account(payment_mean, type: :code)
      raise ArgumentError('invalid type') unless %i[code label].include?(type)

      Setting.get("accounting_#{payment_mean}_client_#{type}")
    end

    def vat_account(type: :code)
      raise ArgumentError('invalid type') unless %i[code label].include?(type)

      Setting.get("accounting_VAT_#{type}")
    end

    def sales_account(invoice_item, type: :code, section: :code)
      raise ArgumentError('invalid type') unless %i[code label].include?(type)
      raise ArgumentError('invalid section') unless %i[code analytical_section].include?(section)

      case invoice_item.object_type
      when 'Reservation'
        reservation_account_code(invoice_item, type: type, section: section)
      when 'Subscription'
        subscription_account_code(invoice_item, type: type, section: section)
      when 'StatisticProfilePrepaidPack'
        Setting.get("accounting_Pack_#{type}") unless section == :analytical_section
      when 'OrderItem'
        product_account_code(invoice_item, type: type, section: section)
      when 'WalletTransaction'
        Setting.get("accounting_wallet_#{type}") unless section == :analytical_section
      else
        Setting.get("accounting_#{invoice_item.object_type}_#{type}") unless section == :analytical_section
      end
    end

    def reservation_account_code(invoice_item, type: :code, section: :code)
      raise ArgumentError('invalid type') unless %i[code label].include?(type)
      raise ArgumentError('invalid section') unless %i[code analytical_section].include?(section)

      if type == :code
        item_code = Setting.get('advanced_accounting') ? invoice_item.object.reservable.advanced_accounting.send(section) : nil
        return Setting.get("accounting_#{invoice_item.object.reservable_type}_code") if item_code.nil? && section == :code

        item_code
      else
        Setting.get("accounting_#{invoice_item.object.reservable_type}_label")
      end
    end

    def subscription_account_code(invoice_item, type: :code, section: :code)
      raise ArgumentError('invalid type') unless %i[code label].include?(type)
      raise ArgumentError('invalid section') unless %i[code analytical_section].include?(section)

      if type == :code
        item_code = Setting.get('advanced_accounting') ? invoice_item.object.plan.advanced_accounting&.send(section) : nil
        return Setting.get('accounting_subscription_code') if item_code.nil? && section == :code

        item_code
      else
        Setting.get('accounting_subscription_label')
      end
    end

    def product_account_code(invoice_item, type: :code, section: :code)
      raise ArgumentError('invalid type') unless %i[code label].include?(type)
      raise ArgumentError('invalid section') unless %i[code analytical_section].include?(section)

      if type == :code
        item_code = Setting.get('advanced_accounting') ? invoice_item.object.orderable.advanced_accounting&.send(section) : nil
        return Setting.get('accounting_Product_code') if item_code.nil? && section == :code

        item_code
      else
        Setting.get('accounting_Product_label')
      end
    end
  end
end
