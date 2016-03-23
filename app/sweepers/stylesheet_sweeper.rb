class StylesheetSweeper < ActionController::Caching::Sweeper
  observe Stylesheet

  def after_update(record)
    if record.contents_changed?
      expire_page(:controller => 'stylesheets', action: 'show', id: record.id)
    end
  end
end