class Rss::ProjectsController < Rss::RssController

  def index
    @projects = Project.includes(:project_image, :users).published.order('created_at desc').limit(10)
    @fab_name = Setting.find_by(name: 'fablab_name').value
  end
end
