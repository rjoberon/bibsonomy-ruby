# coding: utf-8

require 'optparse'
require 'citeproc'
require 'csl/styles'
require 'bibtex'
require 'json'
require 'bibsonomy'

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
# 
# Changes:
# 2015-02-24
# - initial version
#
# TODO:
# - escape data
# - make sorting, etc. configurable
# - add link to BibSonomy
# - automatically rename files (TODO: CSL lacks BibTeX key)
# - add intra_hash, user_name, DOI to CSL
# - add CSL to BibSonomy API
# - extract core into separate (standalone) module
# - integrate command line parsing
# - integrate AJAX abstract


module BibSonomy
  class CSL

    def initialize(user_name, api_key, pdf_dir)
      super()
      @bibsonomy = BibSonomy::API.new(user_name, api_key, 'csl')
      @pdf_dir = pdf_dir
    end

    def render(user, tag, count, style)
      # get posts from BibSonomy
      posts = JSON.parse(@bibsonomy.get_posts_for_user(user, "publication", [tag], 0, count))

      # render them with citeproc
      cp = CiteProc::Processor.new style: style, format: 'html'
      cp.import posts

      # to check for duplicate file names
      file_names = []

      # sort posts by year
      sorted_keys = posts.keys.sort { |a,b| get_sort_posts(posts[b], posts[a]) }

      result = ""

      # print first heading
      last_year = 0

      if sorted_keys.length > 0
        last_year = get_year(posts[sorted_keys[0]])
        result += "<h3>" + last_year + "</h3>"
      end

      result += "<ul class='publications'>\n"
      for post_id in sorted_keys
        post = posts[post_id]
        # print heading
        year = get_year(post)
        if year != last_year
          last_year = year
          result += "</ul>\n<h3>" + last_year + "</h3>\n<ul class='publications'>\n"
        end

        # render metadata
        csl = cp.render(:bibliography, id: post_id)
        result += "<li class='" + post["type"] + "'>#{csl[0]} <span class='opt'>["
        # extract the post's id
        intra_hash, user_name = get_intra_hash(post_id)
        # attach documents
        if @pdf_dir
          for doc in get_public_docs(post["documents"])
            # fileHash, fileName, md5hash, userName
            file_path = get_document(@bibsonomy, intra_hash, user_name, doc, @pdf_dir, file_names)
            result += "<a href='#{file_path}'>PDF</a> | "
          end
        end
        # attach DOI
        doi = post["DOI"]
        if doi != ""
          result += "DOI:<a href='http://dx.doi.org/#{doi}'>#{doi}</a> | "
        end
        # attach URL
        url = post["URL"]
        if url != ""
          result += "<a href='#{url}'>URL</a> | "
        end
        # attach BibTeX
        result += "<a href='http://www.bibsonomy.org/bib/publication/#{intra_hash}/#{user_name}'>BibTeX</a> | "
        # attach link to BibSonomy
        result += "<a href='http://www.bibsonomy.org/publication/#{intra_hash}/#{user_name}'>BibSonomy</a>]</span>"
        result += "</li>\n"
      end
      result += "</ul>\n"

      return result
    end

    def get_year(post)
      return post["issued"]["literal"]
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
      return [get_year(a), a["type"], person_b[0]["family"]] <=> [get_year(b), b["type"], person_a[0]["family"]]
    end

    #
    # only show PDF files and if
    #
    def get_public_docs(documents)
      result = []
      for doc in documents
        file_name = doc["fileName"]
        if file_name.end_with? ".pdf"
                              if documents.length < 2 or file_name.end_with? "_oa.pdf"
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
      # strip "_oa"
      if file_name.end_with? "_oa.pdf"
                           file_name = file_name[0, file_name.length - "_oa.pdf".length] + ".pdf"
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


  # parse command line options
  def self.main(args)

    # setting default options
    options = OpenStruct.new
    options.documents = false
    options.directory = nil
    options.tags = []
    options.style = "apa.csl"
    options.posts = 1000

    opt_parser = OptionParser.new do |opts|
      opts.banner = "Usage: csl.rb [options] user_name api_key"

      opts.separator ""
      opts.separator "Specific options:"

      # mandatory arguments are handled separately
      
      # optional arguments
      opts.on('-u', '--user USER', 'return posts for USER instead of user') { |v| options[:user] = v }
      opts.on('-t', '--tags TAG,TAG,...', Array, 'return posts with the given tags') { |v| options[:tags] = v }
      opts.on('-s', '--style STYLE', 'use CSL style STYLE for rendering') { |v| options[:style] = v }
      opts.on('-n', '--number-of-posts [COUNT]', Integer, 'number of posts to download') { |v| options[:posts] = v }
      opts.on('-d', '--directory DIR', 'target directory', '  (if not given, no documents are downloaed)') { |v| options[:directory] = v }

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

    # set defaults for optional arguments
    options[:user] = options[:user_name] unless options[:user]

    #
    # do the actual work
    #
    csl = BibSonomy::CSL.new(options[:user_name], options[:api_key], options[:directory])

    html = csl.render(options[:user], options[:tags], options[:posts], options[:style])

    return html

  end

end
