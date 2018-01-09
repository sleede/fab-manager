class SocialBotController < ActionController::Base
  def share
    case request.original_fullpath
      when /(=%2F|\/)projects(%2F|\/)([\-0-9a-z_]+)/
        @project = Project.friendly.find("#{$3}")
        render :project, status: :ok
      when /(=%2F|\/)events(%2F|\/)([0-9]+)/
        @event = Event.find("#{$3}".to_i)
        render :event, status: :ok
      when /(=%2F|\/)trainings(%2F|\/)([\-0-9a-z_]+)/
        @training = Training.friendly.find("#{$3}")
      render :training, status: :ok
      else
        puts "unknown bot request : #{request.original_url}"
    end
  end

end