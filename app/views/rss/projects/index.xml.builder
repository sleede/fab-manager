#encoding: UTF-8

xml.instruct! :xml, version: '1.0'
xml.rss version: '2.0' do
  xml.channel do
    xml.title "#{t('app.public.projects_list.projects_list.the_fablab_projects')} - #{@fab_name}"
    xml.description t('app.public.home.latest_documented_projects')
    xml.author @fab_name
    xml.link root_url + '#!/projects'
    xml.language I18n.locale.to_s

    @projects.each do |project|
      xml.item do
        xml.guid project.id
        xml.pubDate project.created_at.strftime('%F %T')
        xml.title project.name
        xml.link root_url + '#!/projects/' + project.slug
        xml.author project.author&.user&.profile&.full_name
        xml.description project.description
        if project.project_image&.attachment?
          xml.enclosure url: root_url + project.project_image.attachment.large.url, length: project.project_image.attachment.large.size, type: project.project_image.attachment.content_type
        end
      end
    end
  end
end
