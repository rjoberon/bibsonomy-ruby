# BibSonomy

BibSonomy client for Ruby

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

Rendering posts with CSL:

```ruby
require 'bibsonomy/csl'
csl = BibSonomy::CSL.new('yourusername', 'yourapikey', nil)
html = csl.render('jaeschke', ['myown'], 100, 'apa.csl')
print html
```


## Contributing

1. Fork it ( https://github.com/rjoberon/bibsonomy-ruby/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
