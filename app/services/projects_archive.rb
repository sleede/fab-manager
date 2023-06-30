class ProjectsArchive
  attr_reader :projects

  def initialize(projects)
    @projects = projects
  end

  def call
    stringio = Zip::OutputStream.write_buffer do |zio|
      projects.includes(:project_image, :themes,
                        :project_caos, :status, :machines,
                        :components, :licence,
                        project_steps: :project_step_images,
                        author: { user: :profile },
                        users: :profile).find_each do |project|
        zio.put_next_entry("#{project.name.parameterize}-#{project.id}.md")
        zio.write ProjectToMarkdown.new(project).call
      end
    end
    stringio.string
  end
end