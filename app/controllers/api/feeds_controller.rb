class API::FeedsController < API::ApiController

  respond_to :json

  def twitter_timelines
    if params
      limit = params[:limit]
    else
      limit = 3
    end
    from_account = Setting.find_by(name: 'twitter_name').try(:value) || ENV['TWITTER_NAME']
    begin
      @tweet_news = Feed.twitter.user_timeline(from_account, {count: limit})
    rescue Twitter::Error::BadRequest => e
      STDERR.puts "[WARNING] Unable to retrieve the twitter feed, please check your ENV configuration. Details: #{e.message}"
      render status: :no_content
    end
  end

end
