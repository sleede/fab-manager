module OpenAPI::V1::Concerns::ParamGroups
  extend ActiveSupport::Concern

  included do
    define_param_group :pagination do
      param :page, Integer, desc: "Page number", optional: true
      param :per_page, Integer, desc: "Number of objects per page. Default is #{OpenAPI::V1::BaseDoc::PER_PAGE_DEFAULT}.", optional: true
    end

    # define_param_group :order_type do
    #   param :order_type, ['asc', 'desc'], desc: "order type: descendant or ascendant. Default value is *desc*."
    # end
    #
    # define_param_group :filter_by_tags do
    #   param :tagged_with, [String, Array], desc: 'If multiple tags are given, we use an *OR* function. See parameter *order_by_matching_tag_count* to order the result. It can also be a *comma* *separated* *string*. Example: tagged_with=science,museum'
    #   param :order_by_matching_tag_count, ['t',1,'true'], desc: "You can use this parameter if you are sending a parameter *tagged_with*. Send this parameter to order by number of matching tags (descendant): result will be sort firstly by matching tags and secondly by order given by *order_by* parameter. Default to *false*."
    # end
    #
    # define_param_group :filter_by_blog do
    #   param :blog_slug, String, desc: "Send the blog's *slug* to only return articles belonging to specific blog."
    # end
    #
    # define_param_group :filter_by_geolocation do
    #   param :latitude, Numeric, desc: "Latitude. Example: *45.166670*"
    #   param :longitude, Numeric, desc: "Longitude. Example: *5.7166700*"
    #   param :radius, Numeric, desc: "To be combined with parameters latitude and longitude. Default to *10*."
    #   param :order_by_distance, ['t',1,'true'], desc: "You can use this parameter if you are sending parameters *latitude* and *longitude*. Send this parameter to order by distance (descendant): result will be sort firstly by distance and secondly by order given by *order_by* parameter. Default to *false*."
    # end
  end
end
