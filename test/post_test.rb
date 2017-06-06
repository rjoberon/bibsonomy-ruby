require './test/test_helper'

class BibSonomyPostTest < Minitest::Test

  def setup
    @api = BibSonomy::API.new(ENV['BIBSONOMY_USER_NAME'], ENV['BIBSONOMY_API_KEY'], 'ruby')
  end
  
  def test_exists
    assert BibSonomy::Post
    assert BibSonomy::API
  end
  
  def test_get_post
    VCR.use_cassette('get_post') do
      post = @api.get_post("bibsonomy-ruby", "c9437d5ec56ba949f533aeec00f571e3")
      assert_equal BibSonomy::Post, post.class
      
      # Check that the fields are accessible by our model
      assert_equal "bibsonomy-ruby", post.user_name
      assert_equal "c9437d5ec56ba949f533aeec00f571e3", post.intra_hash
      assert_equal "The Social Bookmark and Publication Management System {BibSonomy}", post.title
      assert_equal "2010", post.year
    end
  end

  def test_get_posts_for_user
    VCR.use_cassette('get_posts_for_user') do
      result = @api.get_posts_for_user("bibsonomy-ruby", "publication", ["test"], 0, 20)
      
      # Make sure we got all the posts
      assert_equal 2, result.length
      
      # Make sure that the JSON was parsed
      assert result.kind_of?(Array)
      assert result.first.kind_of?(BibSonomy::Post)
    end      
  end

  def test_get_posts_for_group
    VCR.use_cassette('get_posts_for_group') do
      result = @api.get_posts_for_group("iccs", "publication", ["test"], 0, 10)
      
      # Make sure we got all the posts
      assert_equal 2, result.length
      
      # Make sure that the JSON was parsed
      assert result.kind_of?(Array)
      assert result.first.kind_of?(BibSonomy::Post)
    end      
  end

  def test_get_posts_user
    VCR.use_cassette('get_posts_user') do
      result = @api.get_posts("user", "bibsonomy-ruby", "publication", ["test"], 0, 10)
      
      # Make sure we got all the posts
      assert_equal 2, result.length
      
      # Make sure that the JSON was parsed
      assert result.kind_of?(Array)
      assert result.first.kind_of?(BibSonomy::Post)
    end      
  end

  def test_get_posts_group
    VCR.use_cassette('get_posts_group') do
      result = @api.get_posts("group", "iccs", "publication", ["test"], 0, 10)
      
      # Make sure we got all the posts
      assert_equal 2, result.length
      
      # Make sure that the JSON was parsed
      assert result.kind_of?(Array)
      assert result.first.kind_of?(BibSonomy::Post)
    end      
  end


  def test_get_document_href
    assert_equal "/api/users/bibsonomy-ruby/posts/c9437d5ec56ba949f533aeec00f571e3/documents/paper.pdf", @api.get_document_href("bibsonomy-ruby", "c9437d5ec56ba949f533aeec00f571e3", "paper.pdf")
  end

  def test_get_document
    VCR.use_cassette('get_document') do
      pdf, mimetype = @api.get_document("bibsonomy-ruby", "c9437d5ec56ba949f533aeec00f571e3", "test.pdf")
      assert_equal "application/octet-stream;charset=UTF-8", mimetype
      assert_equal "A test file\n", pdf
    end
  end


  def test_get_document_preview
    VCR.use_cassette('get_document_preview') do
      jpeg, mimetype = @api.get_document_preview("bibsonomy-ruby", "c9437d5ec56ba949f533aeec00f571e3", "test.pdf", "SMALL")
      assert_equal "image/jpeg", mimetype
      assert_equal ["ffd8ffe00010"].pack('H*') + "JFIF", jpeg[0..9]
    end
  end

end
