require 'test_helper'

class CssRewriterTest < Test::Unit::TestCase

  context "The CssRewriter" do

    setup do
      CloudfrontAssetHost.configure do |config|
        config.cname  = "assethost.com"
        config.bucket = "bucketname"
        config.key_prefix = ""
        config.enabled = false
      end

      @stylesheet_path = File.join(Rails.public_path, 'stylesheets', 'style.css')
    end

    should "rewrite a single css file" do
      tmp = CloudfrontAssetHost::CssRewriter.rewrite_stylesheet(@stylesheet_path)
      contents = File.read(tmp.path)
      contents.split("\n").each do |line|
        assert_equal "body { background-image: url(http://assethost.com/d41d8cd98/images/image.png); }", line
      end
    end

  end

end
