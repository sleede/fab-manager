class API::ProjectsController < API::ApiController
  before_action :authenticate_user!, except: [:index, :show, :last_published, :search]
  before_action :set_project, only: [:update, :destroy]
  respond_to :json

  def index
    # DEPEND per(12) -> projects.coffee
    @projects = policy_scope(Project).page(params[:page]).per(12)
  end

  def last_published
    @projects = Project.includes(:project_image).published.order('created_at desc').limit(5)
  end

  def show
     @project = Project.friendly.find(params[:id])
  end

  def create
    @project = Project.new(project_params.merge(author_id: current_user.id))
    if @project.save
      render :show, status: :created, location: @project
    else
      render json: @project.errors, status: :unprocessable_entity
    end
  end

  def update
    authorize @project
    if @project.update(project_params)
      render :show, status: :ok, location: @project
    else
      render json: @project.errors, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @project
    @project.destroy
    head :no_content
  end

  def collaborator_valid
    project_user = ProjectUser.find_by(valid_token: params[:valid_token])
    if project_user
      project_user.update(is_valid: true, valid_token: '')
      redirect_to "/#!/projects/#{project_user.project.id}" and return
    end
    redirect_to root_url
  end

  def search
    query_params = JSON.parse(params[:search])
    records = Project.search(query_params, current_user).page(params[:page]).records
    @total = records.total
    @projects = records.includes(:users, :project_image)
    render :index
  end

  def allowed_extensions
    render json: ENV['ALLOWED_EXTENSIONS'].split(' '), status: :ok
  end

  private
    def set_project
      @project = Project.find(params[:id])
    end

    def project_params
      params.require(:project).permit(:name, :description, :tags, :machine_ids, :component_ids, :theme_ids, :licence_id, :author_id, :licence_id, :state,
                                      user_ids: [], machine_ids: [], component_ids: [], theme_ids: [], project_image_attributes: [:attachment],
                                      project_caos_attributes: [:id, :attachment, :_destroy],
                                      project_steps_attributes: [:id, :description, :title, :_destroy, :step_nb,
                                        :project_step_images_attributes => [:id, :attachment, :_destroy]])
    end
end
