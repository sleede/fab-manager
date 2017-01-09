namespace :fablab do
  # desc "Get all stripe plans and create in fablab app"
  # task stripe_plan: :environment do
  #   Stripe::Plan.all.data.each do |plan|
  #     unless Plan.find_by(stp_plan_id: plan.id)
  #       group = Group.friendly.find(plan.id.split('-').first)
  #       if group
  #         Plan.create(stp_plan_id: plan.id, name: plan.name, amount: plan.amount, interval: plan.interval, group_id: group.id, skip_create_stripe_plan: true)
  #       else
  #         puts plan.name + " n'a pas été créé. [error]"
  #       end
  #     end
  #   end
  #
  #   if Plan.column_names.include? "training_credit_nb"
  #     Plan.all.each do |p|
  #       p.update_columns(training_credit_nb: (p.interval == 'month' ? 1 : 5))
  #     end
  #   end
  # end

  desc 'Regenerate the invoices'
  task :regenerate_invoices, [:year, :month] => :environment do |task, args|
    year = args.year || Time.now.year
    month = args.month || Time.now.month
    start_date = Time.new(year.to_i, month.to_i, 1)
    end_date = start_date.next_month
    puts "-> Start regenerate the invoices between #{I18n.l start_date, format: :long} in #{I18n.l end_date-1.minute, format: :long}"
    invoices = Invoice.only_invoice.where('created_at >= :start_date AND created_at < :end_date', {start_date: start_date, end_date: end_date}).order(created_at: :asc)
    invoices.each(&:regenerate_invoice_pdf)
    puts '-> Done'
  end

  desc 'Cancel stripe subscriptions'
  task cancel_subscriptions: :environment do
    Subscription.where('expired_at >= ?', Time.now.at_beginning_of_day).each do |s|
      puts "-> Start cancel subscription of #{s.user.email}"
      s.cancel
      puts '-> Done'
    end
  end

  desc '(re)Build ElasticSearch fablab base for stats'
  task es_build_stats: :environment do

    puts "DELETE stats"
    `curl -XDELETE http://#{ENV["ELASTICSEARCH_HOST"]}:9200/stats`

    puts "PUT index stats"
    `curl -XPUT http://#{ENV["ELASTICSEARCH_HOST"]}:9200/stats`

    %w[account event machine project subscription training user].each do |stat|
      puts "PUT Mapping stats/#{stat}"
        `curl -XPUT http://#{ENV["ELASTICSEARCH_HOST"]}:9200/stats/#{stat}/_mapping -d '
      {
         "properties": {
            "type": {
               "type": "string",
               "index" : "not_analyzed"
            },
            "subType": {
               "type": "string",
               "index" : "not_analyzed"
            },
            "date": {
               "type": "date"
            },
            "name": {
               "type": "string",
               "index" : "not_analyzed"
            }
         }
      }';`
    end
    es_add_event_filters
  end

  desc 'add event filters to statistics'
  task es_add_event_filters: :environment do
    es_add_event_filters
  end

  def es_add_event_filters
    `curl -XPUT http://#{ENV["ELASTICSEARCH_HOST"]}:9200/stats/event/_mapping -d '
      {
         "properties": {
            "ageRange": {
               "type": "string",
               "index" : "not_analyzed"
            },
            "eventTheme": {
               "type": "string",
               "index" : "not_analyzed"
            }
         }
      }';`
  end

  desc 'sync all/one project in ElasticSearch index'
  task :es_build_projects_index, [:id] => :environment do |task, args|
    client = Project.__elasticsearch__.client
    # create index if not exists
    unless client.indices.exists? index: Project.index_name
      client.indices.create Project.index_name
    end
    # delete doctype if exists
    if client.indices.exists_type? index: Project.index_name, type: Project.document_type
      client.indices.delete_mapping index: Project.index_name, type: Project.document_type
    end
    # create doctype
    client.indices.put_mapping index: Project.index_name, type: Project.document_type, body: Project.mappings.to_hash

    # index requested documents
    if args.id
      ProjectIndexerWorker.perform_async(:index, id)
    else
      Project.pluck(:id).each do |project_id|
        ProjectIndexerWorker.perform_async(:index, project_id)
      end
    end
  end

  desc 'sync all/one availabilities in ElasticSearch index'
  task :es_build_availabilities_index, [:id] => :environment do |task, args|
    client = Availability.__elasticsearch__.client
    # create index if not exists
    unless client.indices.exists? index: Availability.index_name
      client.indices.create Availability.index_name
    end
    # delete doctype if exists
    if client.indices.exists_type? index: Availability.index_name, type: Availability.document_type
      client.indices.delete_mapping index: Availability.index_name, type: Availability.document_type
    end
    # create doctype
    client.indices.put_mapping index: Availability.index_name,  type: Availability.document_type, body: Availability.mappings.to_hash

    # verify doctype creation was successful
    if client.indices.exists_type? index: Availability.index_name, type: Availability.document_type
      puts "[ElasticSearch] #{Availability.index_name}/#{Availability.document_type} successfully created with its mapping."

      # index requested documents
      if args.id
        AvailabilityIndexerWorker.perform_async(:index, id)
      else
        Availability.pluck(:id).each do |availability_id|
          AvailabilityIndexerWorker.perform_async(:index, availability_id)
        end
      end
    else
      puts "[ElasticSearch] An error occurred while creating #{Availability.index_name}/#{Availability.document_type}. Please check your ElasticSearch configuration."
      puts "\nCancelling..."
    end
  end

  desc 'recreate every versions of images'
  task build_images_versions: :environment do
    Project.find_each do |project|
      project.project_image.attachment.recreate_versions! if project.project_image.present? and project.project_image.attachment.present?
    end
    ProjectStepImage.find_each do |project_step_image|
      project_step_image.attachment.recreate_versions! if project_step_image.present? and project_step_image.attachment.present?
    end
    Machine.find_each do |machine|
      machine.machine_image.attachment.recreate_versions! if machine.machine_image.present?
    end
    Event.find_each do |event|
      event.event_image.attachment.recreate_versions! if event.event_image.present?
    end

  end


  desc 'switch the active authentication provider'
  task :switch_auth_provider, [:provider] => :environment do |task, args|
    unless args.provider
      fail 'FATAL ERROR: You must pass a provider name to activate'
    end

    unless AuthProvider.find_by(name: args.provider) != nil
      providers = AuthProvider.all.inject('') do |str, item|
        str += item[:name]+', '
      end
      fail "FATAL ERROR: the provider '#{args.provider}' does not exists. Available providers are: #{providers[0..-3]}"
    end

    if AuthProvider.active.name == args.provider
      fail "FATAL ERROR: the provider '#{args.provider}' is already enabled"
    end

    # disable previous provider
    prev_prev = AuthProvider.find_by(status: 'previous')
    unless prev_prev.nil?
      prev_prev.update_attribute(:status, 'pending')
    end
    AuthProvider.active.update_attribute(:status, 'previous')

    # enable given provider
    AuthProvider.find_by(name: args.provider).update_attribute(:status, 'active')

    # migrate the current users.
    if AuthProvider.active.providable_type != DatabaseProvider.name
      User.all.each do |user|
        # Concerns any providers except local database
        user.generate_auth_migration_token
      end
    else
      User.all.each do |user|
        # Concerns local database provider
        user.update_attribute(:auth_token, nil)
      end
    end

    # ask the user to restart the application
    puts "\nActivation successful"

    puts "\n/!\\ WARNING: Please consider the following, otherwise the authentication will be bogus:"
    puts "\t1) CLEAN the cache with `rake tmp:clear`"
    puts "\t2) REBUILD the assets with `rake assets:precompile`"
    puts "\t3) RESTART the application"
    puts "\t4) NOTIFY the current users with `rake fablab:notify_auth_changed`\n\n"

  end

  desc 'notify users that the auth provider has changed'
  task notify_auth_changed: :environment do

    I18n.locale = I18n.default_locale

    # notify every users if the provider is not local database provider
    if AuthProvider.active.providable_type != DatabaseProvider.name
      User.all.each do |user|
        NotificationCenter.call type: 'notify_user_auth_migration',
                                receiver: user,
                                attached_object: user
      end
    end

    puts "\nUsers successfully notified\n\n"
  end

  desc 'generate fixtures from db'
  task generate_fixtures: :environment do
    Rails.application.eager_load!
    ActiveRecord::Base.descendants.reject { |c| c == ActiveRecord::SchemaMigration or c == PartnerPlan }.each do |ar_base|
      p "========== #{ar_base} =============="
      ar_base.dump_fixtures
    end
  end

  desc 'clean stripe secrets from VCR cassettes'
  task clean_cassettes_secrets: :environment do
    Dir['test/vcr_cassettes/*.yml'].each do |cassette_file|
      cassette = File.read(cassette_file)
      cassette.gsub!(Rails.application.secrets.stripe_api_key, 'sk_test_testfaketestfaketestfake')
      cassette.gsub!(Rails.application.secrets.stripe_publishable_key, 'pk_test_faketestfaketestfaketest')
      puts cassette
      File.write(cassette_file, cassette)
    end
  end

  desc '(re)generate statistics in elasticsearch for the past period'
  task :generate_stats, [:period] => :environment do |task, args|
    unless args.period
      fail 'FATAL ERROR: You must pass a number of days (=> past period) to generate statistics on'
    end

    days = args.period.to_i
    days.times.each do |i|
      StatisticService.new.generate_statistic({start_date: i.day.ago.beginning_of_day,end_date: i.day.ago.end_of_day})
    end
  end


  desc 'set slugs to plans'
  task set_plans_slugs: :environment do
    # this will maintain compatibility with existing statistics
    Plan.all.each do |p|
      p.slug = p.stp_plan_id
      p.save
    end
  end
end
