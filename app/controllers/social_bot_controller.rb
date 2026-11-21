# frozen_string_literal: true

# Render minimal HTML pages with OpenGraph / Twitter Card meta tags, so that link previews
# (WhatsApp, Telegram, Signal, Slack, Discord, LinkedIn, Facebook, X...) show the shared item.
#
# Two entry points are available:
# - the share routes (/events/:id, /trainings/:id, /projects/:id), independent of the user agent.
#   Humans are immediately redirected to the matching page of the single page application (/#!/...)
# - the legacy root route, used by some bots with the deprecated "_escaped_fragment_" AJAX crawling scheme
class SocialBotController < ActionController::Base
  DESCRIPTION_LENGTH = 300

  rescue_from ActiveRecord::RecordNotFound do
    head :not_found
  end

  def event
    render_share(find_event(params[:id]))
  end

  def training
    render_share(find_training(params[:id]))
  end

  def project
    render_share(find_project(params[:id]))
  end

  # legacy route for bots using the "_escaped_fragment_" scheme (eg. /?_escaped_fragment_=/events/1)
  def share
    case request.original_fullpath
    when %r{(=%2F|/)projects(%2F|/)([\-0-9a-z_]+)}
      render_share(find_project(Regexp.last_match(3)))
    when %r{(=%2F|/)events(%2F|/)([0-9]+)}
      render_share(find_event(Regexp.last_match(3)))
    when %r{(=%2F|/)trainings(%2F|/)([\-0-9a-z_]+)}
      render_share(find_training(Regexp.last_match(3)))
    else
      Rails.logger.warn "unknown bot request : #{request.original_url}"
      head :not_found
    end
  end

  private

  def find_event(id)
    Event.where(deleted_at: nil).find(id.to_s.to_i)
  end

  def find_training(id)
    Training.where(disabled: [false, nil]).friendly.find(id.to_s)
  end

  def find_project(id)
    Project.published.friendly.find(id.to_s)
  end

  def render_share(record)
    @share = share_data(record)
    render :show, status: :ok
  end

  def share_data(record)
    path, title, image = case record
                         when Event then ["events/#{record.id}", record.title, record.event_image]
                         when Training then ["trainings/#{record.slug}", record.name, record.training_image]
                         else ["projects/#{record.slug}", record.name, record.project_image]
                         end
    {
      title: title,
      description: plain_text(record.description),
      url: absolute_url("/#{path}"),
      app_url: absolute_url("/#!/#{path}"),
      image: image_data(image)
    }
  end

  # @return [String] the description without HTML tags, with normalized white spaces, truncated on a word boundary
  def plain_text(html)
    text = Nokogiri::HTML.fragment(html.to_s).text.squish
    text.truncate(DESCRIPTION_LENGTH, separator: ' ', omission: '…')
  end

  # @return [Hash, nil] the absolute URL and the dimensions of the "large" version of the given image
  def image_data(image)
    version = image&.attachment&.large
    return nil if version.blank? || version.url.blank?

    width, height = begin
      version.dimensions
    rescue StandardError
      [nil, nil]
    end
    { url: absolute_url(version.url), width: width, height: height }
  end

  # @param path [String] absolute path, starting with a slash
  def absolute_url(path)
    "#{base_url}#{path}"
  end

  # Same host as the links sent by email (DEFAULT_HOST / DEFAULT_PROTOCOL), or the requested host when it is not configured
  def base_url
    host = Rails.application.secrets.default_host
    return request.base_url if host.blank?

    "#{Rails.application.secrets.default_protocol.presence || request.scheme}://#{host}"
  end
end
