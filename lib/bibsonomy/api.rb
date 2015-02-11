# coding: utf-8
require 'faraday'
require 'json'

$API_URL = "https://www.bibsonomy.org/"

module BibSonomy
  class API

    def initialize(user_name, api_key, format='ruby')
      @conn = Faraday.new(:url => $API_URL) do |faraday|
        faraday.request  :url_encoded             # form-encode POST params
        #faraday.response :logger
        faraday.adapter  Faraday.default_adapter  # make requests with Net::HTTP
      end

      if format == 'ruby'
        @format = 'json'
        @parse = true
      else
        @format = format
        @parse = false
      end
      
      @conn.basic_auth(user_name, api_key)

    end

    
    def find(user_name, intra_hash)
      response = @conn.get "/api/users/#{user_name}/posts/#{intra_hash}" , { :format => @format }
      if @parse
        attributes = JSON.parse(response.body)
        return Post.new(attributes["post"])
      end
      return response.body
    end

    
    def all(user_name, tags = nil, count)
      params = { :format => @format, :resourcetype => 'bibtex', :start => 0, :end => count}
      if tags != nil
        params[:tags] = tags.join(" ")
      end
      response = @conn.get "/api/users/#{user_name}/posts", params

      if @parse
        posts = JSON.parse(response.body)["posts"]["post"]
        return posts.map { |attributes| Post.new(attributes) }
      end
      return response.body
    end
    
  end
end
