# frozen_string_literal: true

# Handle requests originated by indexer bots of social networks
class SocialBotController < ActionController::Base
  def share
    case request.original_fullpath
    when %r{(=%2F|/)projects(%2F|/)([\-0-9a-z_]+)}
      @project = Project.friendly.find(Regexp.last_match(3).to_s)
      render :project, status: :ok
    when %r{(=%2F|/)events(%2F|/)([0-9]+)}
      @event = Event.find(Regexp.last_match(3).to_s.to_i)
      render :event, status: :ok
    when %r{(=%2F|/)trainings(%2F|/)([\-0-9a-z_]+)}
      @training = Training.friendly.find(Regexp.last_match(3).to_s)
      render :training, status: :ok
    else
      puts "unknown bot request : #{request.original_url}"
    end
  end
end
