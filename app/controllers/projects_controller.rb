class ProjectsController < ApplicationController

  before_filter :set_project, only: [:edit, :show, :update, :confirm_destroy,
                                        :destroy, :tagged_entries]
  before_filter :check_permissions, only: [:update, :confirm_destroy, :destroy]

  def index
    @projects = current_user.projects.ordered
    count = @projects.count(distinct: true)
    @projects = @projects.paginate(page: params[:page], total_entries: count)
  end

  def new
    @project = Project.new
  end

  def create
    @project = Project.new(params[:project])
    if @project.save
      redirect_to projects_path, notice: project_flash(@project).html_safe
    else
      render :new
    end
  end

  def edit
    @tags = @project.entries.tag_counts_on(:tags).order(:name)
  end

  def update
    if @project.update_attributes(params[:project])
      redirect_to projects_path, notice: project_flash(@project).html_safe
    else
      render :edit
    end
  end

  def confirm_destroy
  end

  def destroy
    @project.destroy
    redirect_to(projects_path, notice: "Awesome. You deleted #{@project.name}")
  end

  def paginate
    projects = current_user.projects.skinny.ordered.limit(30).offset(params[:idx])
    render json: projects.to_json(methods: [:entry_count])
  end

  def search
    query = params[:term]
    @projects = Project.skinny.where("name ILIKE ?", "%#{query}%")
    respond_to do |format|
      format.html
      format.json {
        render json: @projects.map{ |p| { name: p.name, id: p.id } }
      }
    end
  end

  def tagged_entries
    tags = params[:tags]
    @entries = @project.entries
    unless tags.blank?
      @entries = @entries.tagged_with(params[:tags])
    end
    @entries = @entries.skinny.ordered

    respond_to do |format|
      format.html
      format.json {
        render json: @entries.to_json(methods: [:project_guid, :project_name])
      }
    end
  end

  private
    def check_permissions
      return redirect_to project_path(@project) unless current_user.can_edit? @project
    end

    def project_flash project
      render_to_string partial: "flash", locals: { project: project }
    end

    def set_project
      @project = Project.find_by_guid!(params[:id])
    end

end
