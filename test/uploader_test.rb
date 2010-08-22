require 'test_helper'

class UploaderTest < Test::Unit::TestCase

  context "A configured uploader" do
    setup do
      @css_md5 = CloudfrontAssetHost.send(:md5sum, 'test/app/public/stylesheets/style.css')[0..8]       #7026e6ce3
      @js_md5 =  CloudfrontAssetHost.send(:md5sum, 'test/app/public/javascripts/application.js')[0..8]  #8ed41cb87
      CloudfrontAssetHost.configure do |config|
        config.cname  = "assethost.com"
        config.bucket = "bucketname"
        config.key_prefix = ""
        config.s3_config = "#{RAILS_ROOT}/config/s3.yml"
        config.enabled = false
      end
    end

    should "be able to retrieve s3-config" do
      config = CloudfrontAssetHost::Uploader.config
      assert_equal 'access_key', config['access_key_id']
      assert_equal 'secret', config['secret_access_key']
    end

    should "be able to instantiate s3-interface" do
      RightAws::S3.expects(:new).with('access_key', 'secret').returns(mock)
      assert_not_nil CloudfrontAssetHost::Uploader.s3
    end

    should "glob current files" do
      assert_equal 3, CloudfrontAssetHost::Uploader.current_paths.length
    end

    should "calculate keys for paths" do
      keys_with_paths = CloudfrontAssetHost::Uploader.keys_with_paths
      assert_equal 3, keys_with_paths.length
      assert_match %r{/test/app/public/javascripts/application\.js$}, keys_with_paths["#{@js_md5}/javascripts/application.js"]
    end

    should "calculate gzip keys for paths" do
      gz_keys_with_paths = CloudfrontAssetHost::Uploader.gzip_keys_with_paths
      assert_equal 2, gz_keys_with_paths.length
      assert_match %r{/test/app/public/javascripts/application\.js$}, gz_keys_with_paths["gz/#{@js_md5}/javascripts/application.js"]
      assert_match %r{/test/app/public/stylesheets/style\.css$},      gz_keys_with_paths["gz/#{@css_md5}/stylesheets/style.css"]
    end

    should "return a mimetype for an extension" do
      assert_equal 'application/x-javascript', CloudfrontAssetHost::Uploader.ext_to_mime['js']
    end

    should "construct the headers for a path" do
      headers = CloudfrontAssetHost::Uploader.headers_for_path('js')
      assert_equal 'application/x-javascript', headers['Content-Type']
      assert_match /max-age=\d+/, headers['Cache-Control']
      assert DateTime.parse(headers['Expires'])
    end

    should "add gzip-header" do
      headers = CloudfrontAssetHost::Uploader.headers_for_path('js', true)
      assert_equal 'application/x-javascript', headers['Content-Type']
      assert_equal 'gzip', headers['Content-Encoding']
      assert_match /max-age=\d+/, headers['Cache-Control']
      assert DateTime.parse(headers['Expires'])
    end

    should "retrieve existing keys" do
      bucket_mock = mock
      bucket_mock.expects(:keys).with({'prefix' => ''}).returns([stub(:name => "keyname")])
      bucket_mock.expects(:keys).with({'prefix' => 'gz'}).returns([stub(:name => "gz/keyname")])

      CloudfrontAssetHost::Uploader.expects(:bucket).times(2).returns(bucket_mock)
      assert_equal ["keyname", "gz/keyname"], CloudfrontAssetHost::Uploader.existing_keys
    end

    should "upload files when there are no existing keys" do
      bucket_mock = mock
      bucket_mock.expects(:put).times(5)
      CloudfrontAssetHost::Uploader.stubs(:bucket).returns(bucket_mock)
      CloudfrontAssetHost::Uploader.stubs(:existing_keys).returns([])

      CloudfrontAssetHost::Uploader.upload!
    end

    should "not re-upload existing keys" do
      CloudfrontAssetHost::Uploader.expects(:bucket).never
      CloudfrontAssetHost::Uploader.stubs(:existing_keys).returns(
        ["gz/#{@js_md5}/javascripts/application.js", "#{@js_md5}/javascripts/application.js",
         "d41d8cd98/images/image.png",
         "#{@css_md5}/stylesheets/style.css", "gz/#{@css_md5}/stylesheets/style.css"]
      )

      CloudfrontAssetHost::Uploader.upload!
    end

    should "correctly gzip files" do
      path = File.join(RAILS_ROOT, 'public', 'javascripts', 'application.js')
      contents = File.read(path)

      gz_path = CloudfrontAssetHost::Uploader.gzipped_path(path)
      gunzip_contents = `gunzip #{gz_path} -q -c`

      assert_equal contents, gunzip_contents
    end

    should "correctly rewrite css files" do
      path = File.join(RAILS_ROOT, 'public', 'stylesheets', 'style.css')
      css_path = CloudfrontAssetHost::Uploader.rewritten_css_path(path)

      File.read(css_path).split("\n").each do |line|
        assert_equal "body { background-image: url(http://assethost.com/d41d8cd98/images/image.png); }", line
      end
    end

  end
end