# frozen_string_literal: true

# API Controller for resources of type DoDoc
class API::DoDocsController < API::APIController
  before_action :authenticate_user!, except: %i[index show]
  before_action :set_do_doc, only: %i[show update destroy]

  def index
    @do_docs = DoDoc.all
  end

  def show; end

  def create
    authorize DoDoc
    @do_doc = DoDoc.new(do_doc_params)
    if @do_doc.save
      render :show, status: :created, location: @do_doc
    else
      render json: @do_doc.errors, status: :unprocessable_entity
    end
  end

  def update
    authorize DoDoc
    if @do_doc.update(do_doc_params)
      render :show, status: :ok, location: @do_doc
    else
      render json: @do_doc.errors, status: :unprocessable_entity
    end
  end

  def destroy
    authorize DoDoc
    @do_doc.destroy
    head :no_content
  end

  private

  def set_do_doc
    @do_doc = DoDoc.find(params[:id])
  end

  def do_doc_params
    params.require(:do_doc).permit(:name, :url)
  end
end
