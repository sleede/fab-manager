json.array!(@tweet_news) do |tweet|
  json.id tweet.id
  json.text auto_link(tweet.text)
end
