class API::FeedsController < API::ApiController

  respond_to :json

  def twitter_timelines
    if params
      limit = params[:limit]
    else
      limit = 3
    end
    from_account = Setting.find_by(name: 'twitter_name').try(:value) || ENV['TWITTER_NAME']
    @tweet_news = Feed.twitter.user_timeline(from_account, {count: limit})
  end

end
