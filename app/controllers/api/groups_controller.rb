class API::GroupsController < API::ApiController
  def index
    @groups = Group.all
  end
end
