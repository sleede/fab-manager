class API::CategoriesController < API::ApiController
  def index
    @categories = Category.all
  end
end
