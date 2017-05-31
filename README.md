# BibSonomy

[BibSonomy](http://www.bibsonomy.org/) client for Ruby

[![Gem Version](https://badge.fury.io/rb/bibsonomy.svg)](http://badge.fury.io/rb/bibsonomy)
[![Build Status](https://travis-ci.org/rjoberon/bibsonomy-ruby.svg?branch=master)](https://travis-ci.org/rjoberon/bibsonomy-ruby)
[![Coverage Status](https://coveralls.io/repos/rjoberon/bibsonomy-ruby/badge.svg)](https://coveralls.io/r/rjoberon/bibsonomy-ruby)

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

## Testing

Get an API-Key from <http://www.bibsonomy.org/settings?selTab=1> and
then run the following commands:

```shell
export BIBSONOMY_USER_NAME="yourusername"
export BIBSONOMY_API_KEY="yourapikey"
bundle exec rake test
```

## Supported API Calls

- `get_post`: [post details](https://bitbucket.org/bibsonomy/bibsonomy/wiki/documentation/api/methods/DetailsForPost) 
- `get_posts_for_user`:
[posts for a user](https://bitbucket.org/bibsonomy/bibsonomy/wiki/documentation/api/methods/ListOfPostsForUser)
- `get_posts_for_group` : posts for a group (= posts of the group members)
- `get_document`: documents for post
- `get_document_preview`: preview image for a document
- `get_posts`: [posts for a user or group](https://bitbucket.org/bibsonomy/bibsonomy/wiki/documentation/api/methods/ListOfAllPosts)

## Jekyll

This gem is used by the
[BibSonomy plugin](https://github.com/rjoberon/bibsonomy-jekyll) for
[Jekyll](http://jekyllrb.com/) to render post lists in Jekyll web
sites. For an example output, have a look at
[my publication list](http://www.kbs.uni-hannover.de/~jaeschke/publications.html).

## Contributing

1. Fork it ( https://github.com/rjoberon/bibsonomy-ruby/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
