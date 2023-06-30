class ProjectToMarkdown
  attr_reader :project

  def initialize(project)
    @project = project
  end

  def call
    md = []

    md << "# #{project.name}"

    md << "![#{I18n.t('app.shared.project.illustration')}](#{full_url(project.project_image.attachment.url)})" if project.project_image

    md << ReverseMarkdown.convert(project.description.to_s)

    project_steps = project.project_steps

    if project_steps.present?
      md << "## #{I18n.t('app.shared.project.steps')}"

      project_steps.each do |project_step|
        md << "### #{I18n.t('app.shared.project.step_N').gsub('{INDEX}', project_step.step_nb.to_s)} : #{project_step.title}"
        md << ReverseMarkdown.convert(project_step.description.to_s)

        project_step.project_step_images.each_with_index do |image, i|
          md << "![#{I18n.t('app.shared.project.step_image')} #{i+1}](#{full_url(project.project_image.attachment.url)})"
        end
      end
    end

    md << "## #{I18n.t('app.shared.project.author')}"
    md << project.author&.user&.profile&.full_name

    if project.themes.present?
      md << "## #{I18n.t('app.shared.project.themes')}"
      md << project.themes.map(&:name).join(', ')
    end

    if project.project_caos.present?
      md << "## #{I18n.t('app.shared.project.CAD_files')}"
      project.project_caos.each do |cao|
        md << "![#{cao.attachment_identifier}](#{full_url(cao.attachment_url)})"
      end
    end

    if project.status
      md << "## #{I18n.t('app.shared.project.status')}"
      md << project.status.name
    end

    if project.machines.present?
      md << "## #{I18n.t('app.shared.project.employed_machines')}"
      md << project.machines.map(&:name).join(', ')
    end

    if project.components.present?
      md << "## #{I18n.t('app.shared.project.employed_materials')}"
      md << project.components.map(&:name).join(', ')
    end

    if project.users.present?
      md << "## #{I18n.t('app.shared.project.collaborators')}"
      md << project.users.map { |u| u.profile.full_name }.join(', ')
    end

    if project.licence.present?
      md << "## #{I18n.t('app.shared.project.licence')}"
      md << project.licence.name
    end

    if project.tags.present?
      md << "## #{I18n.t('app.shared.project.tags')}"
      md << project.tags
    end


    md = md.reject { |line| line.blank? }

    md.join("\n\n")
  end

  private

  def full_url(path)
    "#{Rails.application.routes.url_helpers.root_url[...-1]}#{path}"
  end
end