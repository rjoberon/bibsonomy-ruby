# BibcsOnomy

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

```
api = BibSonomy::API.new('yourusername', 'yourapikey')
posts = api.find('jaeschke', 20)
```

## Contributing

1. Fork it ( https://github.com/rjoberon/bibsonomy-ruby/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
