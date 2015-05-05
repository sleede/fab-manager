class API::FeedsController < API::ApiController

  respond_to :json

  def twitter_timelines
    if params
      limit = params[:limit]
    else
      limit = 3
    end
    @tweet_news = Feed.twitter.user_timeline(ENV['TWITTER_NAME'], {count: limit})
  end

end
