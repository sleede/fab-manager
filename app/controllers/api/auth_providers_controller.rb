class API::AuthProvidersController < API::ApiController

  before_action :set_provider, only: [:show, :update, :destroy]

  def index
    @providers = policy_scope(AuthProvider)
  end

  def create
    authorize AuthProvider
    @provider = AuthProvider.new(provider_params)
    if @provider.save
      render :show, status: :created, location: @provider
    else
      render json: @provider.errors, status: :unprocessable_entity
    end
  end

  def update
    authorize AuthProvider
    if @provider.update(provider_params)
      render :show, status: :ok, location: @provider
    else
      render json: @provider.errors, status: :unprocessable_entity
    end
  end

  def show
    authorize AuthProvider
  end

  def destroy
    authorize AuthProvider
    @provider.destroy
    head :no_content
  end

  def mapping_fields
    authorize AuthProvider
    render :mapping_fields, status: :ok
  end

  def active
    authorize AuthProvider
    @provider = AuthProvider.active
  end

  private

    def set_provider
      @provider = AuthProvider.find(params[:id])
    end

    def provider_params
      if params['auth_provider']['providable_type'] == DatabaseProvider.name
        params.require(:auth_provider).permit(:name, :providable_type)
      elsif params['auth_provider']['providable_type'] == OAuth2Provider.name
      params.require(:auth_provider).permit(:name, :providable_type, providable_attributes: [
                                                     :id, :base_url, :token_endpoint, :authorization_endpoint, :profile_url, :client_id, :client_secret,
                                                     o_auth2_mappings_attributes: [
                                                         :id, :local_model, :local_field, :api_field, :api_endpoint, :api_data_type, :_destroy,
                                                         transformation: [:type, :format, :true_value, :false_value, mapping: [:from, :to]]
                                                     ]
                                                 ])
      end
    end

end