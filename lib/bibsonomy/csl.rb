# coding: utf-8
require 'citeproc'
require 'csl/styles'
require 'optparse'
require "bibsonomy/api"

#
# Generates a list of publication posts from BibSonomy
#
# required parameters:
# - user name
# - api key
# optional parameters:
# - user name
# - tags
# - number of posts
# - style
# - directory
# - pdf_link_prefix
# - group
# - altmetric
#
# Changes:
# 2018-10-13
# - added pdf_link_prefix
# 2018-08-09 (rja)
# - shortened DOI URL
# 2017-07-05 (rja)
# - added support for Altmetric badges
# - adapted options for command line use to support groups
# 2017-06-06 (rja)
# - added support for DOIs which are actually URLs (i.e., include the resolver)
# 2017-05-31 (rja)
# - added support to get posts of a group
# 2017-01-19 (rja)
# - added optional parameter group to control which posts are
#   included based on their viewability for a specific group (not yet activated!)
# 2015-02-24 (rja)
# - initial version
#
# @todo escape data
# @todo make sorting, etc. configurable
# @todo automatically rename files (TODO: CSL lacks BibTeX key)
# @todo add intra_hash, user_name, etc. to CSL (cf. https://bitbucket.org/bibsonomy/bibsonomy/issue/2411/)
# @todo integrate AJAX abstract
# @todo make all options available via command line
# @todo support filtering of posts by group (viewability)
#
# @author Robert Jäschke

module BibSonomy
  class CSL

    # @return [String] the output directory for downloaded PDF files. If set to `nil`, no documents are downloaded. (default: `nil`)
    attr_accessor :pdf_dir

    # @return [String] prefix of link to downloaded PDFs. E.g., to prepend a slash (default: ``)
    attr_accessor :pdf_link_prefix

    # @return [String] the {http://citationstyles.org/ CSL} style used for rendering. (default: `apa.csl`)
    attr_accessor :style

    # @return [Boolean] whether year headings shall be rendered. (default: `true`)
    attr_accessor :year_headings

    # @return [String] the CSS class used to render the surrounding `<ul>` list (default: 'publications')
    attr_accessor :css_class

    # @return [Boolean] whether links for DOIs shall be rendered. (default: `true`)
    attr_accessor :doi_link

    # @return [Boolean] whether URLs of posts shall be rendered. (default: `true`)
    attr_accessor :url_link

    # @return [Boolean] whether links to the BibTeX data of a post (in BibSonomy) shall be rendered. (default: `true`)
    attr_accessor :bibtex_link

    # @return [Boolean] whether links to BibSonomy shall be rendered. (default: `true`)
    attr_accessor :bibsonomy_link

    # @return [String] the separator between options. (default: ' | ')
    attr_accessor :opt_sep

    # @return [String] the badge type for embedded Altmetric badges. If set to `nil`, no badge is included. (default: `nil`)
    attr_accessor :altmetric_badge_type

    # @return [String] When a post has several documents and the
    #   filename of one of them ends with `public_doc_postfix`, only
    #   this document is downloaded and linked, all other are
    #   ignored. (default: '_oa.pdf')
    attr_accessor :public_doc_postfix

    # @return [String] which posts shall be included, based on the groups they are viewable for
    attr_accessor :group

    #
    # Create a new BibSonomy instance.
    #
    # @param user_name [String] the BibSonomy user name
    # @param api_key [String] the API key of the user (get at https://www.bibsonomy.org/settings?selTab=1)
    def initialize(user_name, api_key)
      super()
      @bibsonomy = BibSonomy::API.new(user_name, api_key, 'csl')
      # setting some defaults
      @style = 'apa.csl'
      @pdf_dir = nil
      @pdf_link_prefix = ''
      @css_class = 'publications'
      @year_headings = true
      @public_doc_postfix = '_oa.pdf'
      @group = 'public'
      @altmetric_badge_type = nil

      # optional parts to be rendered (or not)
      @doi_link = true
      @url_link = true
      @bibtex_link = true
      @bibsonomy_link = true
      @opt_sep = ' | '
    end

    #
    # Download `count` posts for the given `user` and `tag(s)` and render them with {http://citationstyles.org/ CSL}.
    #
    # @param grouping [String] the type of the name (either "user" or "group")
    # @param name [String] the name of the group or user
    # @param tags [Array<String>] the tags that all posts must contain (can be empty)
    # @param count [Integer] number of posts to download
    # @return [String] the rendered posts as HTML
    def render(grouping, name, tags, count)
      # get posts from BibSonomy
      posts = JSON.parse(@bibsonomy.get_posts(grouping, name, 'publication', tags, 0, count))

      # render them with citeproc
      cp = CiteProc::Processor.new style: @style, format: 'html'
      cp.import posts

      # to check for duplicate file names
      file_names = []

      # filter posts by group
      # 2017-05-30, rja, disabled until group information is returned by the API
      # posts.delete_if do |v|
      #   if v["group"] == @group
      #     true
      #   else
      #     print("WARN: " + v["group"])
      #     false
      #   end
      # end

      # sort posts by year
      sorted_keys = posts.keys.sort { |a,b| get_sort_posts(posts[b], posts[a]) }

      result = ""

      # print first heading
      last_year = 0

      if @year_headings and sorted_keys.length > 0
        last_year = get_year(posts[sorted_keys[0]])
        result += "<h3>" + last_year + "</h3>"
      end

      result += "<ul class='#{@css_class}'>\n"
      for post_id in sorted_keys
        post = posts[post_id]

        # print heading
        if @year_headings
          year = get_year(post)
          if year != last_year
            last_year = year
            result += "</ul>\n<h3>" + last_year + "</h3>\n<ul class='#{@css_class}'>\n"
          end
        end

        # render metadata
        csl = cp.render(:bibliography, id: post_id)
        result += "<li class='" + post["type"] + "'>#{csl[0]}"

        # extract the post's id
        intra_hash, user_name = get_intra_hash(post_id)

        # optional parts
        options = []
        # attach documents
        if @pdf_dir
          for doc in get_public_docs(post["documents"])
            # fileHash, fileName, md5hash, userName
            file_path = get_document(@bibsonomy, intra_hash, user_name, doc, @pdf_dir, file_names)
            options << "<a href='#{@pdf_link_prefix}#{file_path}'>PDF</a>"
          end
        end
        # attach DOI
        doi = post["DOI"]
        if @doi_link and doi != ""
          doi, doi_url = get_doi(doi)
          options << "DOI:<a href='#{doi_url}'>#{doi}</a>"
        end
        # attach URL
        url = post["URL"]
        if @url_link and url != ""
          options << "<a href='#{url}'>URL</a>"
        end
        # attach BibTeX
        if @bibtex_link
          options << "<a href='https://www.bibsonomy.org/bib/publication/#{intra_hash}/#{user_name}'>BibTeX</a>"
        end
        # attach link to BibSonomy
        if @bibsonomy_link
          options << "<a href='https://www.bibsonomy.org/publication/#{intra_hash}/#{user_name}'>BibSonomy</a>"
        end

        # attach options
        if options.length > 0
          result += " <span class='opt'>[" + options.join(@opt_sep) + "]</span>"
        end

        # attach Altmetric badge
        if @altmetric_badge_type and doi != ""
          doi, doi_url = get_doi(doi)
          result += "<div class='altmetric-embed' data-badge-type='#{@altmetric_badge_type}' data-doi='#{doi}'></div>"
        end

        result += "</li>\n"
      end
      result += "</ul>\n"

      return result
    end


    #
    # private methods follow
    #
    private

    # given a DOI (or a URL with a DOI) return DOI and resolvable URL
    def get_doi(doi)
      # simplistic check whether DOI is a URL
      if doi.start_with?("http")
        # extract DOI, regex from https://www.crossref.org/blog/dois-and-matching-regular-expressions/
        if doi =~ /(10.\d{4,9}\/[-._;()\/:A-Z0-9]+)/i
          return $1, doi
        else
          return doi, doi
        end
      else
        return doi, "https://doi.org/#{doi}"
      end
    end

    def get_year(post)
      issued = post["issued"]
      # if the post contains only a "year" field, it is contained in
      # the field "literal"
      if issued["literal"]
        return issued["literal"]
      else
        # otherwise, the date can be contained in the "raw" field
        # TODO: extract the year ([12][0-9]{3}) from that field
        return issued["raw"]
      end
    end

    def get_sort_posts(a, b)
      person_a = a["author"]
      if person_a.length == 0
        person_a = a["editor"]
      end
      person_b = b["author"]
      if person_b.length == 0
        person_b = b["editor"]
      end
      # we switch the order of person_b and person_a, to sort
      # descending by year but ascending by person name
      return [get_year(a), a["type"], person_b[0]["family"]] <=> [get_year(b), b["type"], person_a[0]["family"]]
    end

    #
    # only show PDF files
    #
    def get_public_docs(documents)
      result = []
      for doc in documents
        file_name = doc["fileName"]
        if file_name.end_with? ".pdf"
          if documents.length < 2 or file_name.end_with? @public_doc_postfix
            result << doc
          end
        end
      end
      return result
    end

    def warn(m)
      print("WARN: " + m + "\n")
    end

    #
    # downloads the documents for the posts (if necessary)
    #
    def get_document(bib, intra_hash, user_name, doc, dir, file_names)
      # fileHash, fileName, md5hash, userName
      file_name = doc["fileName"]
      # strip doc prefix for public documents
      if file_name.end_with? @public_doc_postfix
        file_name = file_name[0, file_name.length - @public_doc_postfix.length] + ".pdf"
      end
      # check for possible duplicate file names
      if file_names.include? file_name
        warn "duplicate file name " + file_name + " for post " + intra_hash
      end
      # remember file name
      file_names << file_name
      # produce file path
      file_path = dir + "/" + file_name
      # download PDF if it not already exists
      if not File.exists? file_path
        pdf, mime = bib.get_document(user_name, intra_hash, doc["fileName"])
        if pdf == nil
          warn "could not download file " + intra_hash + "/" + user_name + "/" + file_name
        else
          File.binwrite(file_path, pdf)
        end
      end
      return file_path
    end

    # format of the post ID for CSL: [0-9a-f]{32}USERNAME
    def get_intra_hash(post_id)
      return [post_id[0, 32], post_id[32, post_id.length]]
    end

  end


  # Parse command line options
  #
  # @param args [Array<String>] command line options
  # @return [String] the rendered posts as HTML
  def self.main(args)

    # TODO add "pdf_link_prefix" below
    # setting default options
    options = OpenStruct.new
    options.documents = false
    options.directory = nil
    options.tags = []
    options.style = "apa.csl"
    options.viewable_group = "public"
    options.altmetric = nil
    options.posts = 1000

    opt_parser = OptionParser.new do |opts|
      opts.banner = "Usage: csl.rb [options] user_name api_key"

      opts.separator ""
      opts.separator "Specific options:"

      # mandatory arguments are handled separately

      # optional arguments
      opts.on('-u', '--user USER', 'get posts for USER') { |v| options[:user] = v }
      opts.on('-g', '--group GROUP', 'get posts for GROUP') { |v| options[:group] = v }
      opts.on('-t', '--tags TAG,TAG,...', Array, 'return posts with the given tags') { |v| options[:tags] = v }
      opts.on('-s', '--style STYLE', 'use CSL style STYLE for rendering') { |v| options[:style] = v }
      opts.on('--viewable-group GROUP', 'include only posts viewable for GROUP') { |v| options[:viewable_group] = v }
      opts.on('-n', '--number-of-posts [COUNT]', Integer, 'number of posts to download') { |v| options[:posts] = v }
      opts.on('-d', '--directory DIR', 'target directory', '  (if not given, no documents are downloaed)') { |v| options[:directory] = v }
      opts.on('-a', '--altmetric TYPE', 'render Altmetric badge with type TYPE') { |v| options[:altmetric] = v }

      opts.separator ""
      opts.separator "Common options:"

      opts.on('-h', '--help', 'show this help message and exit') do
        puts opts
        exit
      end

      opts.on_tail('-v', "--version", "show version") do
        puts BibSonomy::VERSION
        exit
      end

    end

    opt_parser.parse!(args)

    # handle mandatory arguments
    begin
      mandatory = [:user_name, :api_key]
      missing = []

      options[:api_key] = args.pop
      missing << :api_key unless options[:api_key]

      options[:user_name] = args.pop
      missing << :user_name unless options[:user_name]

      if not missing.empty?
        puts "Missing options: #{missing.join(', ')}"
        puts opt_parser
        exit
      end
    rescue OptionParser::InvalidOption, OptionParser::MissingArgument
      puts $!.to_s
      puts opt_parser
      exit
    end

    #
    # do the actual work
    #
    csl = BibSonomy::CSL.new(options[:user_name], options[:api_key])
    csl.pdf_dir = options[:directory]
    csl.style = options[:style]
    csl.group = options[:viewable_group]
    csl.altmetric_badge_type = options[:altmetric]

    if options[:group]
      grouping = "group"
      name = options[:group]
    elsif options[:user]
      grouping = "user"
      name = options[:user]
    else
      # default: API user
      grouping = "user"
      name = options[:user_name]
    end

    puts "call: #{grouping}, #{name}"
    html = csl.render(grouping, name, options[:tags], options[:posts])

    return html

  end

end
