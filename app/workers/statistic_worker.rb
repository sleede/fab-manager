class StatisticWorker
  include Sidekiq::Worker

  def perform
    StatisticService.new.generate_statistic
  end
end
