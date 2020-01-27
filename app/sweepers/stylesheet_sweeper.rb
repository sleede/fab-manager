# frozen_string_literal: true

# Build a cached version of the CSS stylesheet
class StylesheetSweeper < ActionController::Caching::Sweeper
  observe Stylesheet

  def after_update(record)
    expire_page(controller: 'stylesheets', action: 'show', id: record.id) if record.contents_changed?
  end
end
