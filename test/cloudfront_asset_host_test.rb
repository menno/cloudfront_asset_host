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

    context "asset-host" do

      setup do
        @gzip_request = stub(:headers => {'Accept-Encoding' => 'gzip, compress'})
        @request = stub(:headers => {})
        @img_source = "/images/logo.png"
        @js_source  = "/javascripts/application.js"
      end

      should "use cname for asset_host" do
        assert_equal "http://assethost.com", CloudfrontAssetHost.asset_host(@img_source, @request)
      end

      should "use bucket_host when cname is not present" do
        CloudfrontAssetHost.cname = nil
        assert_equal "http://bucketname.s3.amazonaws.com", CloudfrontAssetHost.asset_host(@img_source, @request)
      end

      should "add gz to asset_host when applicable" do
        assert_equal "http://assethost.com/gz", CloudfrontAssetHost.asset_host(@js_source, @gzip_request)
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

end
