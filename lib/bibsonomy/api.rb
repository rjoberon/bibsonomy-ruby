# coding: utf-8
require 'faraday'
require 'json'

#
# TODO:
# - error handling
# - getting more than 1000 posts
#

# configuration options
$API_URL = "https://www.bibsonomy.org/"
$MAX_POSTS_PER_REQUEST = 20

#
# allowed shortcuts for resource types
#
$resource_types_bookmark = ['bookmark', 'bookmarks', 'book', 'link', 'links', 'url']
$resource_types_bibtex = ['bibtex', 'pub', 'publication', 'publications', 'publ']

#
# The BibSonomy REST client for Ruby.
#
module BibSonomy
  class API

    # Initializes the client with the given credentials.
    #
    # @param user_name [String] The name of the user account used for
    # accessing the API
    #
    # @param api_key [String] The API key corresponding to the user
    # account - can be obtained from
    # http://www.bibsonomy.org/settings?selTab=1
    #
    # @param format [String] The requested return format. One of:
    # 'xml', 'json', 'ruby', 'csl', 'bibtex'. The default is 'ruby'
    # which returns Ruby objects defined by this library. Currently,
    # 'csl' and 'bibtex' are only available for publications.
    #
    def initialize(user_name, api_key, format = 'ruby')

      # configure output format
      if format == 'ruby'
        @format = 'json'
        @parse = true
      else
        @format = format
        @parse = false
      end

      @conn = Faraday.new(:url => $API_URL) do |faraday|
        faraday.request  :url_encoded             # form-encode POST params
        #faraday.response :logger
        faraday.adapter  Faraday.default_adapter  # make requests with
                                                  # Net::HTTP
      end

      @conn.basic_auth(user_name, api_key)

    end


    #
    # Get a single post
    #
    # @param user_name [String] The name of the post's owner.
    # @param intra_hash [String] The intrag hash of the post.
    # @return [BibSonomy::Post] the requested post
    #
    def get_post(user_name, intra_hash)
      response = @conn.get "/api/users/" + CGI.escape(user_name) + "/posts/" + CGI.escape(intra_hash), { :format => @format }

      if @parse
        attributes = JSON.parse(response.body)
        return Post.new(attributes["post"])
      end
      return response.body
    end

    #
    # Get posts owned by a user, optionally filtered by tags.
    #
    # @param user_name [String] The name of the posts' owner.
    # @resource_type [String] The type of the post. Currently
    # supported are 'bookmark' and 'publication'.
    #
    def get_posts_for_user(user_name, resource_type, tags = nil, start = 0, endc = $MAX_POSTS_PER_REQUEST)
      params = {
        :format => @format,
        :resourcetype => self.get_resource_type(resource_type),
        :start => start,
        :end => endc
      }
      # add tags, if requested
      if tags != nil
        params[:tags] = tags.join(" ")
      end
      response = @conn.get "/api/users/" + CGI.escape(user_name) + "/posts", params

      if @parse
        posts = JSON.parse(response.body)["posts"]["post"]
        return posts.map { |attributes| Post.new(attributes) }
      end
      return response.body
    end

    def get_document_href(user_name, intra_hash, file_name)
      return "/api/users/" + CGI.escape(user_name) + "/posts/" + CGI.escape(intra_hash) + "/documents/" + CGI.escape(file_name)
    end

    #
    # get a document belonging to a post
    #
    def get_document(user_name, intra_hash, file_name)
      response = @conn.get get_document_href(user_name, intra_hash, file_name)
      if response.status == 200
        return [response.body, response.headers['content-type']]
      end
      return nil, nil
    end

    def get_document_preview(user_name, intra_hash, file_name, size)
      response = get_document_href(user_name, intra_hash, file_name), { :preview => size }
      if response.status = 200
        return [response.body, 'image/jpeg']
      end
      return nil, nil
    end

    #
    # Convenience method to allow sloppy specification of the resource
    # type.
    #
    # @private
    #
    def get_resource_type(resource_type)
      if $resource_types_bookmark.include? resource_type.downcase()
        return "bookmark"
      end

      if $resource_types_bibtex.include? resource_type.downcase()
        return "bibtex"
      end

      raise ArgumentError.new("Unknown resource type:  #{resource_type}. Supported resource types are ")
    end

  end
end
