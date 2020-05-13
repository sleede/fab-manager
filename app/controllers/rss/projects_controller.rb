class Rss::ProjectsController < Rss::RssController

  def index
    @projects = Project.includes(:project_image, :users).published.order('created_at desc').limit(10)
    @fab_name = Setting.get('fablab_name')
  end
end
