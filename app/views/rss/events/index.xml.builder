#encoding: UTF-8

xml.instruct! :xml, version: '1.0'
xml.rss version: '2.0', 'xmlns:xCal' => 'urn:ietf:params:xml:ns:xcal' do
  xml.channel do
    xml.title "#{t('app.public.events_list.the_fablab_s_events')} - #{@fab_name}"
    xml.description t('app.public.home.fablab_s_next_events')
    xml.author @fab_name
    xml.link root_url + '#!/events'
    xml.language I18n.locale.to_s

    @events.each do |event|
      xml.item do
        xml.guid event.id
        xml.pubDate event.created_at.strftime('%FT%T%:z')
        xml.title event.name
        xml.link root_url + '#!/events/' + event.id.to_s
        xml.description event.description
        xml.xCal :dtstart do
          xml.text! event.availability.start_at.strftime('%FT%T%:z')
        end
        xml.xCal :dtend do
          xml.text! event.availability.end_at.strftime('%FT%T%:z')
        end
        xml.enclosure url: root_url + event.event_image.attachment.large.url, length: event.event_image.attachment.large.size, type: event.event_image.attachment.content_type if event.event_image
        xml.category event.category.name
      end
    end
  end
end
