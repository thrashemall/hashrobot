class CategoriesController < ApplicationController

  def index

    @categories = Category.all
  end


  def new

  end

  def create

    all_tweets = compile_tweets(Tweet)

    tweet_id = compile_tweet_id(Tweet)

    response = analyze_tweets(all_tweets)

    tweet_category = inject_tweet_id(response, tweet_id)

    save_tweets(tweet_category)

    redirect_to categories_path
  end

  def show

  end

private

  # compile_tweets assumes your tweet_table has a 'content' attribute
  # returns an array of strings
  def compile_tweets(tweets_table)

    # create an empty array to store the content of each tweet
    tweet_content = []

    # get all the tweets from the db
    tweets = tweets_table.all.order(created: :desc)

    # extract the content for each tweet and push it to tweet_content
    tweets.each do |tweet|

      tweet_content << tweet['content']
    end

    # return the content of each tweet
    tweet_content
  end

  # returns an array of integers (id of the tweets in the tweet table)
  def compile_tweet_id(tweets_table)

    # create an empty array to store the id of each tweet
    tweet_id = []

    # get all the tweets from the db
    tweets = tweets_table.all.order(created: :desc)

    # extract the id for each tweet and push it to tweet_id
    tweets.each do |tweet|

      tweet_id << tweet['id']
    end

    # return the id of each tweet
    tweet_id
  end

  # analyse_tweets expects an array of strings
  # returns a JSON object
  def analyze_tweets(tweet_list)

    # get the monkeylearn API token from Figaro
    monkey_token = Figaro.env.monkey_learn_token

    # cl_5icAVzKR is the generic topic classifier endpoint
    uri = URI.parse("https://api.monkeylearn.com/v2/classifiers/cl_5icAVzKR/classify/")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    request = Net::HTTP::Post.new(uri.request_uri)

    # set POST data with the content of each tweet
    # the monkeylean API expects an array of strings
    request.body = {text_list: tweet_list}.to_json

    # set the response type to JSON in the header
    request.add_field("Content-Type", "application/json")

    # pass in the monkeylearn API token in the header
    request.add_field("Authorization", "token #{monkey_token}")

    # parse the monkeylearn response to usable JSON
    response = JSON.parse http.request(request).body
  end

  # once the tweets have been processed
  def inject_tweet_id (response, tweet_id)

    i = 0

    response['result'].each do |t|

      t[0].merge!("id" => tweet_id[i])
      i += 1
    end
  end

  # save the results from the monkeylearn API to the categories table
  def save_tweets(analyzed_tweets)

    #extract the arrays of categories
    result = analyzed_tweets

    #use only the first category result for each tweet and save it to the categories table
    result.each do |t|

      Category.create({:probability => t[0]['probability'], :category => t[0]['label'], :tweet_id => t[0]['id'] })
    end
  end
end
