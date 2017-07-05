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
      html = @csl.render("user", "bibsonomy-ruby", ["doiok"], 10)

      assert_equal "<h3>2010</h3>", html[0..12]
      assert_equal "</ul>", html[-6..-2]
    end
  end

  def test_render_all
    VCR.use_cassette('render_all') do
      html = @csl.render("user", "bibsonomy-ruby", [], 10)

      assert_equal "<h3>2015</h3>", html[0..12]
      assert_equal "<h3>2010</h3>", html[765..777]
      assert_equal "</ul>", html[-6..-2]
    end
  end

  def test_render_doi
    VCR.use_cassette('render_doi') do
      html = @csl.render("user", "bibsonomy-ruby", ["doiok"], 10)
      # DOI is correct
      assert_equal "DOI:<a href='https://dx.doi.org/10.1007/s00778-010-0208-4'>10.1007/s00778-010-0208-4</a>", html[339,88]
    end
  end

  def test_render_broken_doi
    VCR.use_cassette('render_broken_doi') do
      # DOI is a URL
      html = @csl.render("user", "bibsonomy-ruby", ["brokendoi", "test"], 10)
      # thus we have http not https
      assert_equal "DOI:<a href='http://dx.doi.org/10.1145/2786451.2786927'>10.1145/2786451.2786927</a>", html[374,83]
    end
  end

  def test_get_docs
    VCR.use_cassette('get_docs') do
      # DOI is a URL
      @csl.pdf_dir = "docs"
      html = @csl.render("user", "bibsonomy-ruby", ["test", "doiok"], 10)

      assert_equal "<a href='docs/test.pdf'>PDF</a>", html[339,31]
    end
  end
end
