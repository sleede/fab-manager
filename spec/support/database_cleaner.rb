RSpec.configure do |config|

  config.before(:suite) do
    # The :transaction strategy prevents :after_commit hooks from running
    DatabaseCleaner.strategy = :transaction
    DatabaseCleaner.clean_with(:truncation)
    # load seeds only for test
    load "#{Rails.root}/db/test_seeds.rb"
  end

  config.around(:each) do |example|
    DatabaseCleaner.cleaning do
      example.run
    end
  end

end
