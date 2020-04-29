# frozen_string_literal: true

# Stripe relative tasks
namespace :fablab do
  namespace :stripe do

    desc 'Cancel stripe subscriptions'
    task cancel_subscriptions: :environment do
      Subscription.where('expiration_date >= ?', DateTime.current.at_beginning_of_day).each do |s|
        puts "-> Start cancel subscription of #{s.user.email}"
        s.cancel
        puts '-> Done'
      end
    end

    desc 'find any invoices with incoherent total between stripe and DB'
    task :find_incoherent_invoices, [:start_date] => :environment do |_task, args|
      puts 'DEPRECATION WARNING: Will not work for invoices created from version 4.1.0 and above'
      date = Date.parse('2017-05-01')
      if args.start_date
        begin
          date = Date.parse(args.start_date)
        rescue ArgumentError => e
          raise e
        end
      end
      Invoice.where('created_at > ? AND stp_invoice_id IS NOT NULL', date).each do |invoice|
        stp_invoice = Stripe::Invoice.retrieve(invoice.stp_invoice_id)
        next if invoice.amount_paid == stp_invoice.total

        puts "Id: #{invoice.id}, reference: #{invoice.reference}, stripe id: #{stp_invoice.id}, " \
             "invoice total: #{invoice.amount_paid / 100.0}, stripe invoice total: #{stp_invoice.total / 100.0}, " \
             "date: #{invoice.created_at}"
      end
    end


    desc 'clean stripe secrets from VCR cassettes'
    task clean_cassettes_secrets: :environment do
      Dir['test/vcr_cassettes/*.yml'].each do |cassette_file|
        cassette = File.read(cassette_file)
        cassette = cassette.gsub(Rails.application.secrets.stripe_api_key, 'sk_test_testfaketestfaketestfake')
        cassette = cassette.gsub(Rails.application.secrets.stripe_publishable_key, 'pk_test_faketestfaketestfaketest')
        puts cassette
        File.write(cassette_file, cassette)
      end
    end

    desc 'sync users to the stripe database'
    task sync_members: :environment do
      puts 'We create all non-existing customers on stripe. This may take a while, please wait...'
      total = User.online_payers.count
      User.online_payers.each_with_index do |member, index|
        print_on_line "#{index} / #{total}"
        begin
          stp_customer = Stripe::Customer.retrieve member.stp_customer_id
          StripeWorker.perform_async(:create_stripe_customer, member.id) if stp_customer.nil? || stp_customer[:deleted]
        rescue Stripe::InvalidRequestError
          StripeWorker.perform_async(:create_stripe_customer, member.id)
        end
      end
      puts 'Done'
    end

    def print_on_line(str)
      print "#{str}\r"
      $stdout.flush
    end
  end
end
