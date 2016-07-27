namespace :fablab do
  #desc "Get all stripe plans and create in fablab app"
  #task stripe_plan: :environment do
    #Stripe::Plan.all.data.each do |plan|
      #unless Plan.find_by_stp_plan_id(plan.id)
        #group = Group.friendly.find(plan.id.split('-').first)
        #if group
          #Plan.create(stp_plan_id: plan.id, name: plan.name, amount: plan.amount, interval: plan.interval, group_id: group.id, skip_create_stripe_plan: true)
        #else
          #puts plan.name + " n'a pas été créé. [error]"
        #end
      #end
    #end

    #if Plan.column_names.include? "training_credit_nb"
      #Plan.all.each do |p|
        #p.update_columns(training_credit_nb: (p.interval == 'month' ? 1 : 5))
      #end
    #end
  #end

  desc "Regenerate the invoices"
  task :regenerate_invoices, [:year, :month] => :environment do |task, args|
    year = args.year || Time.now.year
    month = args.month || Time.now.month
    start_date = Time.new(year.to_i, month.to_i, 1)
    end_date = start_date.next_month
    puts "-> Start regenerate the invoices between #{I18n.l start_date, format: :long} in #{I18n.l end_date-1.minute, format: :long}"
    invoices = Invoice.only_invoice.where("created_at >= :start_date AND created_at < :end_date", {start_date: start_date, end_date: end_date}).order(created_at: :asc)
    invoices.each(&:regenerate_invoice_pdf)
    puts "-> Done"
  end

  desc "Cancel stripe subscriptions"
  task cancel_subscriptions: :environment do
    Subscription.where("expired_at >= ?", Time.now.at_beginning_of_day).each do |s|
      puts "-> Start cancel subscription of #{s.user.email}"
      s.cancel
      puts "-> Done"
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

  desc "sync all/one project in elastic search index"
  task :es_build_projects_index, [:id] => :environment do |task, args|
    if Project.__elasticsearch__.client.indices.exists? index: 'fablab'
      Project.__elasticsearch__.client.indices.delete index: 'fablab'
    end
    Project.__elasticsearch__.client.indices.create index: Project.index_name, body: { settings: Project.settings.to_hash, mappings: Project.mappings.to_hash }
    if args.id
      IndexerWorker.perform_async(:index, id)
    else
      Project.pluck(:id).each do |project_id|
        IndexerWorker.perform_async(:index, project_id)
      end
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
    puts "\t2) RESTART the application"
    puts "\t3) NOTIFY the current users with `rake fablab:notify_auth_changed`\n\n"

  end

  desc 'notify users that the auth provider has changed'
  task notify_auth_changed: :environment do

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

  desc "generate fixtures from db"
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
end
