# coding: utf-8
require 'faraday'
require 'json'

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
# @todo error handling
# @todo getting more than 1000 posts
#
# @author Robert Jäschke
#
# Changes:
# 2017-05-31 (rja)
# - refactored get_posts_for_group and get_posts_for_user into get_posts
# 2017-05-30 (rja)
# - added get_posts_for_group
#
module BibSonomy
  class API

    # Initializes the client with the given credentials.
    #
    # @param user_name [String] the name of the user account used for accessing the API
    # @param api_key [String] the API key corresponding to the user account - can be obtained from http://www.bibsonomy.org/settings?selTab=1
    #
    # @param format [String] The requested return format. One of:
    #   'xml', 'json', 'ruby', 'csl', 'bibtex'. The default is 'ruby'
    #   which returns Ruby objects defined by this library. Currently,
    #   'csl' and 'bibtex' are only available for publications.
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
    # @param user_name [String] the name of the post's owner
    # @param intra_hash [String] the intrag hash of the post
    # @return [BibSonomy::Post, String] the requested post
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
    # @param user_name [String] the name of the posts' owner
    # @param resource_type [String] the type of the post. Currently supported are 'bookmark' and 'publication'.
    # @param tags [Array<String>] the tags that all posts must contain (can be empty)
    # @param start [Integer] number of first post to download
    # @param endc [Integer] number of last post to download
    # @return [Array<BibSonomy::Post>, String] the requested posts
    def get_posts_for_user(user_name, resource_type, tags = nil, start = 0, endc = $MAX_POSTS_PER_REQUEST)
      return get_posts("user", user_name, resource_type, tags, start, endc)
    end

    #
    # Get the posts of the users of a group, optionally filtered by tags.
    #
    # @param group_name [String] the name of the group
    # @param resource_type [String] the type of the post. Currently supported are 'bookmark' and 'publication'.
    # @param tags [Array<String>] the tags that all posts must contain (can be empty)
    # @param start [Integer] number of first post to download
    # @param endc [Integer] number of last post to download
    # @return [Array<BibSonomy::Post>, String] the requested posts
    def get_posts_for_group(group_name, resource_type, tags = nil, start = 0, endc = $MAX_POSTS_PER_REQUEST)
      return get_posts("group", group_name, resource_type, tags, start, endc)
    end

    #
    # Get posts for a user or group, optionally filtered by tags.
    #
    # @param grouping [String] the type of the name (either "user" or "group")
    # @param name [String] the name of the group or user
    # @param resource_type [String] the type of the post. Currently supported are 'bookmark' and 'publication'.
    # @param tags [Array<String>] the tags that all posts must contain (can be empty)
    # @param start [Integer] number of first post to download
    # @param endc [Integer] number of last post to download
    # @return [Array<BibSonomy::Post>, String] the requested posts
    def get_posts(grouping, name, resource_type, tags = nil, start = 0, endc = $MAX_POSTS_PER_REQUEST)
      params = {
        :format => @format,
        :resourcetype => get_resource_type(resource_type),
        :start => start,
        :end => endc
      }
      # decide what to get
      if grouping == "user"
        params[:user] = name
      elsif grouping == "group"
        params[:group] = name
      end
      # add tags, if requested
      if tags != nil
        params[:tags] = tags.join(" ")
      end

      response = @conn.get "/api/posts", params

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
    # Get a document belonging to a post.
    #
    # @param user_name
    # @param intra_hash
    # @param file_name
    # @return the document and the content type
    def get_document(user_name, intra_hash, file_name)
      response = @conn.get get_document_href(user_name, intra_hash, file_name)
      if response.status == 200
        return [response.body, response.headers['content-type']]
      end
      return nil, nil
    end

    #
    # Get the preview for a document belonging to a post.
    #
    # @param user_name
    # @param intra_hash
    # @param file_name
    # @param size [String] requested preview size (allowed values: SMALL, MEDIUM, LARGE)
    # @return the preview image and the content type `image/jpeg`
    def get_document_preview(user_name, intra_hash, file_name, size)
      response = @conn.get get_document_href(user_name, intra_hash, file_name), { :preview => size }
      if response.status == 200
        return [response.body, 'image/jpeg']
      end
      return nil, nil
    end



    private

    #
    # Convenience method to allow sloppy specification of the resource
    # type.
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
