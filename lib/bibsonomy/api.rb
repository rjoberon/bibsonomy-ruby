require 'faraday'
require 'json'

$API_URL = "https://www.bibsonomy.org/"

module BibSonomy
  class API

    def initialize(user_name, api_key)
      @conn = Faraday.new(:url => $API_URL) do |faraday|
        faraday.request  :url_encoded             # form-encode POST params
        #faraday.response :logger
        faraday.adapter  Faraday.default_adapter  # make requests with Net::HTTP
      end
    
      @conn.basic_auth(user_name, api_key)

    end

    
    def find(user_name, intra_hash)
      response = @conn.get "/api/users/#{user_name}/posts/#{intra_hash}" , { :format => 'json'}
      attributes = JSON.parse(response.body)
      Post.new(attributes["post"])
    end

    
    def all(user_name, count)
      response = @conn.get "/api/users/#{user_name}/posts", { :format => 'json', :resourcetype => 'bibtex' }
      posts = JSON.parse(response.body)["posts"]["post"]
      posts.map { |attributes| Post.new(attributes) }
    end
    
  end
end
