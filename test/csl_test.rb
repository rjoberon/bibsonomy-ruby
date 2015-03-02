require './test/test_helper'

class BibSonomyCSLTest < Minitest::Test

  def setup
    @csl = BibSonomy::CSL.new(ENV['BIBSONOMY_USER_NAME'], ENV['BIBSONOMY_API_KEY'])
  end
  
  def test_exists
    assert BibSonomy::CSL
  end
  
  def test_render
    VCR.use_cassette('render') do
      html = @csl.render("bibsonomy-ruby", [], 10)

      assert_equal "<h3>2010</h3>", html[0..12]
      assert_equal "</ul>", html[-6..-2]
    end
  end
end
