# frozen_string_literal: true

# This class provides logging functionalities for SSO authentication
class SsoLogger
  def initialize
    @logger = ActiveSupport::TaggedLogging.new(Logger.new($stdout))
    @log_status = ENV.fetch('SSO_DEBUG', false)
  end

  def debug(message)
    return unless @log_status

    @logger.tagged('SSO') { @logger.debug(message) }
  end

  def info(message)
    @logger.tagged('SSO') { @logger.info(message) }
  end

  def warn(message)
    @logger.tagged('SSO') { @logger.warn(message) }
  end

  def error(message)
    @logger.tagged('SSO') { @logger.error(message) }
  end
end
