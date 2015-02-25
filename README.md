# BibSonomy

BibSonomy client for Ruby

[![Gem Version](https://badge.fury.io/rb/bibsonomy.svg)](http://badge.fury.io/rb/bibsonomy)

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'bibsonomy'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install bibsonomy

## Usage

Getting posts from BibSonomy:

```ruby
require 'bibsonomy'
api = BibSonomy::API.new('yourusername', 'yourapikey', 'ruby')
posts = api.get_posts_for_user('jaeschke', 'publication', ['myown'], 0, 20)
```

Rendering posts with [CSL](http://citationstyles.org/):

```ruby
require 'bibsonomy/csl'
csl = BibSonomy::CSL.new('yourusername', 'yourapikey')
html = csl.render('jaeschke', ['myown'], 100)
print html
```

A command line wrapper to the CSL renderer:

```ruby
#!/usr/bin/ruby
require 'bibsonomy/csl'
print BibSonomy::main(ARGV)
```

## Jekyll

A [Jekyll](http://jekyllrb.com/) plugin:

```ruby
# coding: utf-8
require 'time'
require 'bibsonomy/csl'

module Jekyll

  class BibSonomyPostList < Liquid::Tag
    def initialize(tag_name, text, tokens)
      super
      parts = text.split(/\s+/)
      @user = parts[0]
      @tag = parts[1]
      @count = Integer(parts[2])
    end

    def render(context)
      site = context.registers[:site]

      # user name and API key for BibSonomy
      user_name = site.config['bibsonomy_user']
      api_key = site.config['bibsonomy_apikey']
      csl = BibSonomy::CSL.new(user_name, api_key)

      # target directory for PDF documents
      pdf_dir = site.config['bibsonomy_document_directory']
      csl.pdf_dir = pdf_dir

      # CSL style for rendering
      style = site.config['bibsonomy_style']
      csl.style = style

      html = csl.render(@user, [@tag], @count)

      # set date to now
      context.registers[:page]["date"] = Time.new

      return html
    end
  end

end

Liquid::Template.register_tag('bibsonomy', Jekyll::BibSonomyPostList)
```

The plugin can be used inside Markdown files as follows:

```Liquid
{% bibsonomy jaeschke myown 100 %}
```

Add the following options to your `_config.yml`:

```YAML
bibsonomy_user: yourusername
bibsonomy_apikey: yourapikey
bibsonomy_document_directory: pdf
# other: apa, acm-siggraph
bibsonomy_style: springer-lecture-notes-in-computer-science
```

For an example, have a look at [my publication list](http://www.kbs.uni-hannover.de/~jaeschke/publications.html).


## Contributing

1. Fork it ( https://github.com/rjoberon/bibsonomy-ruby/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
