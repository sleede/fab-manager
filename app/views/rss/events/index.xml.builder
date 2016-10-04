#encoding: UTF-8

xml.instruct! :xml, version: '1.0'
xml.rss version: '2.0' do
  xml.channel do
    xml.title "#{t('app.public.events_list.the_fablab_s_events')} - #{@fab_name}"
    xml.description t('app.public.home.fablab_s_next_events')
    xml.author @fab_name
    xml.link root_url + '#!/events'
    xml.language I18n.locale.to_s

    @events.each do |event|
      xml.item do
        xml.guid event.id
        xml.pubDate event.created_at.strftime('%F %T')
        xml.title event.name
        xml.link root_url + '#!/events/' + event.id.to_s
        xml.description event.description
      end
    end
  end
end
