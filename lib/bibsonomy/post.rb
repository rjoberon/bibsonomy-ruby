# coding: utf-8

module BibSonomy
  class Post

    attr_reader :user_name, :intra_hash, :title, :year, :entrytype, :booktitle, :journal, :url

    def initialize(post)
      publication = post["bibtex"]
      @user_name = post["user"]["name"]
      @intra_hash = publication["intrahash"]
      @title = publication["title"]
      @year = publication["year"]
      @entrytype = publication["entrytype"]
      @booktitle = publication["booktitle"]
      @journal = publication["journal"]
      @url = publication["url"]
    end
      
  end
end
