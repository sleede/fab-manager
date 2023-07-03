# frozen_string_literal: true

# API Controller for resources of type Project
class API::ProjectsController < API::APIController
  before_action :authenticate_user!, except: %i[index show last_published search]
  before_action :set_project, only: %i[update destroy]
  respond_to :json

  def index
    @projects = policy_scope(Project).page(params[:page])
  end

  def last_published
    @projects = Project.includes(:project_image).published.order('created_at desc').limit(5)
  end

  def show
    @project = Project.friendly.find(params[:id])
  end

  def markdown
    @project = Project.friendly.find(params[:id])
    authorize @project
    send_data ProjectToMarkdown.new(@project).call, filename: "#{@project.name.parameterize}-#{@project.id}.md", disposition: 'attachment', type: 'text/markdown'
  end

  def create
    @project = Project.new(project_params.merge(author_statistic_profile_id: current_user.statistic_profile.id))
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
    service = ProjectService.new
    paginate = request.format.zip? ? false : true
    res = service.search(params, current_user, paginate: paginate)

    render json: res, status: :unprocessable_entity and return if res[:error]

    respond_to do |format|
      format.json do
        @total = res[:total]
        @projects = res[:projects]
        render :index
      end
      format.zip do
        head :forbidden unless current_user.admin? || current_user.manager?

        send_data ProjectsArchive.new(res[:projects]).call, filename: "projets.zip", disposition: 'attachment', type: 'application/zip'
      end
    end
  end

  private

  def set_project
    @project = Project.find(params[:id])
  end

  def project_params
    params.require(:project).permit(:name, :description, :tags, :machine_ids, :component_ids, :theme_ids, :licence_id, :status_id, :state,
                                    user_ids: [], machine_ids: [], component_ids: [], theme_ids: [], project_category_ids: [],
                                    project_image_attributes: [:attachment],
                                    project_caos_attributes: %i[id attachment _destroy],
                                    project_steps_attributes: [
                                      :id, :description, :title, :_destroy, :step_nb,
                                      { project_step_images_attributes: %i[id attachment _destroy] }
                                    ])
  end
end
