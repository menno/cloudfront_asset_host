# CloudFront AssetHost

Easy deployment of your assets on CloudFront or S3. When enabled in production, your assets will be served from CloudFront/S3 which will result in a speedier front-end.

## Why?

Hosting your assets on CloudFront ensures minimum latency for all your visitors. But deploying your assets requires some additional management that this gem provides.

### Expiration

The best way to expire your assets on CloudFront is to upload the asset to a new unique url. The gem will calculate the MD5-hash of the asset and incorporate that into the URL.

### Efficient uploading

By using the MD5-hash we can easily determine which assets aren't uploaded yet. This speeds up the deployment considerably.

### Compressed assets

CloudFront will not serve compressed assets automatically. To counter this, the gem will upload gzipped javascripts and stylesheets and serve them when the user-agent supports it.

## Installing

    gem install cloudfront_asset_host

Add the gem to your `environment.rb` or `Gemfile`.

### Dependencies

The gem relies on the `gzip` utility. Make sure it is available locally.

### Configuration

Make sure your s3-credentials are stored in _config/s3.yml_ like this:

    access_key_id: 'access_key'
    secret_access_key: 'secret'

or with environment specified:

    production:
      access_key_id: 'access_key'
      secret_access_key: 'secret'

Create an initializer to configure the plugin _config/initializers/cloudfront_asset_host.rb_

    # Simple configuration
    CloudfrontAssetHost.configure do |config|
      config.bucket = "bucketname" # required
      config.enabled = true if Rails.env.production? # only enable in production
    end

    # Extended configuration
    CloudfrontAssetHost.configure do |config|
      config.bucket       = "bucketname"        # required
      config.cname        = "assets.domain.com" # cname configured for your distribution or bucket

      config.key_prefix   = "app/"              # prefix for paths
      config.plain_prefix = ""                  # prefix for paths to uncompressed files

      config.asset_dirs   = %w(images flash)    # specify directories to be uploaded
      config.exclude_pattern = /pdf/            # exclude matching assets from uploading

      # s3 configuration
      config.s3_config    = "path/to/s3.yml"    # Alternative location of your s3-config file
      config.s3_logging   = true                # enable logging for this bucket

      # gzip related configuration
      config.gzip = true                      # enable gzipped assets (defaults to true)
      config.gzip_extensions = ['js', 'css']  # only gzip javascript or css (defaults to %w(js css))
      config.gzip_prefix = "gz"               # prefix for gzipped bucket (defaults to "gz")

      config.enabled = true if Rails.env.production? # only enable in production
    end

The _cname_ option also accepts a `Proc` or `String` with the `%d` parameter (e.g. "assets%d.example.com" for multiple hosts).

## Usage

### Uploading your assets
Run `CloudfrontAssetHost::Uploader.upload!(:verbose => true, :dryrun => false)` before your deployment. Put it for example in your Rakefile or Capistrano-recipe. Verbose output will include information about which keys are being uploaded. Enabling _dryrun_ will skip the actual upload if you're just interested to see what will be uploaded.

### Hooks
If the plugin is enabled. Rails' internal `asset_host` and `asset_id` functionality will be overridden to point to the location of the assets on Cloudfront.

### Other plugins
When using in combination with SASS and/or asset_packager it is recommended to generate the css files and package your assets before uploading them to Cloudfront. For example, call     `Sass::Plugin.update_stylesheets` and `Synthesis::AssetPackage.build_all` first.

## Changelog

  - 1.1
    - New features:
      - Add support for CNAME-interpolation [wpeterson]
      - Add ability to specify an exclude regex for CDN content [wpeterson]
      - Configure directories to upload through CloudfrontAssetHost.asset_dirs [wpeterson]
      - CloudfrontAssetHost.cname accepts Proc [foresth]
      - Rewrite all css-files when some images are modified [foresth]
      - Enable S3-logging with CloudfrontAssetHost.s3_loggin (defaults to false) [foresth]
      - Ability to insert prefix to paths to uncompressed files [foresth]
      - Ability to define environment specific credentials in s3.yml [foresth]

    - Fixes and improvements:
      - Strip query-parameters from image-urls in CSS [wpeterson]
      - Use Digest::MD5 as md5-implementation [wpeterson, mattdb, foresth]
      - Fix bug working with paths with spaces [caleb]

  - 1.0.2
    - Fix bug serving gzipped-assets to IE

  - 1.0.1
    - First release

## Contributing

Feel free to fork the project and send pull requests.

## Contributors

Thanks to these people who contributed patches:

  * [Winfield](http://github.com/wpeterson)
  * [Caleb Land](http://github.com/caleb)
  * [foresth](http://github.com/foresth)

## Compatibility

Tested on Rails 2.3.5 with SASS and AssetPackager plugins

## Copyright

Created at [Wakoopa](http://wakoopa.com)

Copyright (c) 2010 Menno van der Sman, released under the MIT license
