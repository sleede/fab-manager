class SocialBotController < ActionController::Base
  def share
    case request.original_fullpath
      when /=%2Fprojects%2F([\-0-9a-z]+)/
        @project = Project.friendly.find("#{$1}")
      else
        puts "unknown bot request : #{request.original_url}"
    end
  end

end