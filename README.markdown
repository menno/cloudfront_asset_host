# CloudFront AssetHost

Easy deployment of your assets on CloudFront or S3. When enabled in production, your assets will be served from Cloudfront/S3 which will result in a speedier front-end.

## Installing

Include the gem in your app's `environment.rb` or Gemfile. It is hosted at Gemcutter[http://gemcutter.org/gems/cloudfront_asset_host]

### Dependencies

Make sure your s3-credentials are stored in _config/s3.yml_ like this:

    access_key_id: 'access_key'
    secret_access_key: 'secret'

The gem relies on +openssl md5+ and +gzip+ utilities. Make sure they are available locally and on your servers.

### Configuration
Create an initializer to configure the plugin _config/initializers/cloudfront_asset_host.rb_

    # Simple configuration
    CloudfrontAssetHost.configure do |config|
      config.bucket = "bucketname" # required
      config.enabled = true if Rails.env.production? # only enable in production
    end

    # Extended configuration
    CloudfrontAssetHost.configure do |config|
      config.bucket     = "bucketname"        # required
      config.cname      = "assets.domain.com" # if you have a cname configured for your distribution or bucket
      config.key_prefix = "app/"              # if you share the bucket and want to keep things separated
      config.s3_config  = "#{RAILS_ROOT}/config/s3.yml" # Alternative location of your s3-config file

      # gzip related configuration
      config.gzip       = true                # enable gzipped assets (defaults to true)
      config.gzip_extensions = ['js', 'css']  # only gzip javascript or css (defaults to %w(js css))
      config.gzip_prefix = "gz"               # prefix for gzipped bucket (defaults to "gz")

      config.enabled    = true if Rails.env.production? # only enable in production
    end

## Usage

### Uploading your assets
Run `CloudfrontAssetHost::Uploader.upload!(:verbose => true, :dryrun => false)` before your deployment. Put it for example in your Rakefile or capistrano-recipe. Verbose output will include information about which keys are being uploaded. Enabling _dryrun_ will skip the actual upload if you're just interested to see what will be uploaded.

### Hooks
If the plugin is enabled. Rails' internal `asset_host` and `asset_id` functionality will be overridden to point to the location of the assets on Cloudfront.

### Other plugins
When using in combination with SASS and/or asset_packager it is recommended to generate the css-files and package your assets before uploading them to Cloudfront. For example, call     `Sass::Plugin.update_stylesheets` and `Synthesis::AssetPackage.build_all` first.

## Compatibility

Tested on Rails 2.3.5 with SASS and AssetPackager plugins

## Copyright

Created at Wakoopa

Copyright (c) 2010 Menno van der Sman, released under the MIT license
