require './test/test_helper'

class BibSonomyPostTest < Minitest::Unit::TestCase

  def setup
    @api = BibSonomy::API.new(ENV['USER_NAME'], ENV['API_KEY'], 'ruby')
  end
  
  def test_exists
    assert BibSonomy::Post
    assert BibSonomy::API
  end
  
  def test_find_post
    VCR.use_cassette('one_post') do
      post = @api.get_post("jaeschke", "c9437d5ec56ba949f533aeec00f571e3")
      assert_equal BibSonomy::Post, post.class
      
      # Check that the fields are accessible by our model
      assert_equal "jaeschke", post.user_name
      assert_equal "c9437d5ec56ba949f533aeec00f571e3", post.intra_hash
      assert_equal "The Social Bookmark and Publication Management System {BibSonomy}", post.title
      assert_equal "2010", post.year
    end
  end

  def test_find_posts
    VCR.use_cassette('all_posts') do
      result = @api.get_posts_for_user("jaeschke", "publication", nil, 0, 20)
      
      # Make sure we got all the posts
      assert_equal 20, result.length
      
      # Make sure that the JSON was parsed
      assert result.kind_of?(Array)
      assert result.first.kind_of?(BibSonomy::Post)
    end      
  end
end
