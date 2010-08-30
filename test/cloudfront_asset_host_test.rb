require 'test_helper'

class CloudfrontAssetHostTest < Test::Unit::TestCase

  context "A configured plugin" do
    setup do
      CloudfrontAssetHost.configure do |config|
        config.cname  = "assethost.com"
        config.bucket = "bucketname"
        config.key_prefix = ""
        config.enabled = false
      end
    end

    should "add methods to asset-tag-helper" do
      assert ActionView::Helpers::AssetTagHelper.private_method_defined?('rails_asset_id_with_cloudfront')
      assert ActionView::Helpers::AssetTagHelper.private_method_defined?('rewrite_asset_path_with_cloudfront')
    end

    should "not enable itself by default" do
      assert_equal false, CloudfrontAssetHost.enabled
      assert_equal "", ActionController::Base.asset_host
    end

    should "return key for path" do
      assert_equal "8ed41cb87", CloudfrontAssetHost.key_for_path(File.join(RAILS_ROOT, 'public', 'javascripts', 'application.js'))
    end

    should "prepend prefix to key" do
      CloudfrontAssetHost.key_prefix = "prefix/"
      assert_equal "prefix/8ed41cb87", CloudfrontAssetHost.key_for_path(File.join(RAILS_ROOT, 'public', 'javascripts', 'application.js'))
    end

    should "default asset_dirs setting" do
      assert_equal "images,javascripts,stylesheets", CloudfrontAssetHost.asset_dirs
    end

    context "asset-host" do

      setup do
        @source  = "/javascripts/application.js"
      end

      should "use cname for asset_host" do
        assert_equal "http://assethost.com", CloudfrontAssetHost.asset_host(@source)
      end

      should "use interpolated cname for asset_host" do
        CloudfrontAssetHost.cname = "assethost-%d.com"
        assert_equal "http://assethost-3.com", CloudfrontAssetHost.asset_host(@source)
      end

      should "use bucket_host when cname is not present" do
        CloudfrontAssetHost.cname = nil
        assert_equal "http://bucketname.s3.amazonaws.com", CloudfrontAssetHost.asset_host(@source)
      end

      should "not support gzip for images" do
        request = stub(:headers => {'User-Agent' => 'Mozilla/5.0', 'Accept-Encoding' => 'gzip, compress'})
        source  = "/images/logo.png"
        assert_equal "http://assethost.com", CloudfrontAssetHost.asset_host(source, request)
      end

      context "when taking the headers into account" do

        should "support gzip for IE" do
          request = stub(:headers => {'User-Agent' => 'Mozilla/4.0 (compatible; MSIE 8.0)', 'Accept-Encoding' => 'gzip, compress'})
          assert_equal "http://assethost.com/gz", CloudfrontAssetHost.asset_host(@source, request)
        end

        should "support gzip for modern browsers" do
          request = stub(:headers => {'User-Agent' => 'Mozilla/5.0', 'Accept-Encoding' => 'gzip, compress'})
          assert_equal "http://assethost.com/gz", CloudfrontAssetHost.asset_host(@source, request)
        end

        should "support not support gzip for Netscape 4" do
          request = stub(:headers => {'User-Agent' => 'Mozilla/4.0', 'Accept-Encoding' => 'gzip, compress'})
          assert_equal "http://assethost.com", CloudfrontAssetHost.asset_host(@source, request)
        end

        should "require gzip in accept-encoding" do
          request = stub(:headers => {'User-Agent' => 'Mozilla/5.0'})
          assert_equal "http://assethost.com", CloudfrontAssetHost.asset_host(@source, request)
        end

      end

    end
  end

  context "An enabled and configured plugin" do
    setup do
      CloudfrontAssetHost.configure do |config|
        config.enabled = true
        config.cname  = "assethost.com"
        config.bucket = "bucketname"
        config.key_prefix = ""
      end
    end

    should "set the asset_host" do
      assert ActionController::Base.asset_host.is_a?(Proc)
    end

    should "alias methods in asset-tag-helper" do
      assert ActionView::Helpers::AssetTagHelper.private_method_defined?('rails_asset_id_without_cloudfront')
      assert ActionView::Helpers::AssetTagHelper.private_method_defined?('rewrite_asset_path_without_cloudfront')
      assert ActionView::Helpers::AssetTagHelper.private_method_defined?('rails_asset_id')
      assert ActionView::Helpers::AssetTagHelper.private_method_defined?('rewrite_asset_path')
    end
  end

  context "An improperly configured plugin" do
    should "complain about bucket not being set" do
      assert_raise(RuntimeError) {
        CloudfrontAssetHost.configure do |config|
          config.enabled = false
          config.cname = "assethost.com"
          config.bucket = nil
        end
      }
    end

    should "complain about missing s3-config" do
      assert_raise(RuntimeError) {
        CloudfrontAssetHost.configure do |config|
          config.enabled = false
          config.cname = "assethost.com"
          config.bucket = "bucketname"
          config.s3_config = "bogus"
        end
      }
    end
  end

  should "respect custom asset_dirs" do
    CloudfrontAssetHost.configure do |config|
      config.bucket = "bucketname"
      config.asset_dirs  = "custom"
    end
    assert_equal "custom", CloudfrontAssetHost.asset_dirs
  end
end
