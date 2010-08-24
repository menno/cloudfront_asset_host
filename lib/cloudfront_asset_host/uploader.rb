require 'right_aws'
require 'tempfile'

module CloudfrontAssetHost
  module Uploader

    class << self

      def upload!(options = {})
        puts "-- Updating uncompressed files" if options[:verbose]
        upload_keys_with_paths(keys_with_paths, options)

        if CloudfrontAssetHost.gzip
          puts "-- Updating compressed files" if options[:verbose]
          upload_keys_with_paths(gzip_keys_with_paths, options.merge(:gzip => true))
        end

        @existing_keys = nil
      end

      def upload_keys_with_paths(keys_paths, options={})
        gzip = options[:gzip] || false
        dryrun = options[:dryrun] || false
        verbose = options[:verbose] || false

        keys_paths.each do |key, path|
          if should_upload?(key, options)
            puts "+ #{key}" if verbose

            extension = File.extname(path)[1..-1]

            path = rewritten_css_path(path)

            data_path = gzip ? gzipped_path(path) : path
            bucket.put(key, File.read(data_path), {}, 'public-read', headers_for_path(extension, gzip)) unless dryrun

            File.unlink(data_path) if gzip && File.exists?(data_path)
          else
            puts "= #{key}" if verbose
          end
        end
      end

      def should_upload?(key, options={})
        options[:force_write] || !existing_keys.include?(key)
      end

      def gzipped_path(path)
        tmp = Tempfile.new("cfah-gz")
        `gzip #{path} -q -c > #{tmp.path}`
        tmp.path
      end

      def rewritten_css_path(path)
        if File.extname(path) == '.css'
          tmp = CloudfrontAssetHost::CssRewriter.rewrite_stylesheet(path)
          tmp.path
        else
          path
        end
      end

      def keys_with_paths
        current_paths.inject({}) do |result, path|
          key = CloudfrontAssetHost.key_for_path(path) + path.gsub(Rails.public_path, '')

          result[key] = path
          result
        end
      end

      def gzip_keys_with_paths
        current_paths.inject({}) do |result, path|
          source = path.gsub(Rails.public_path, '')

          if CloudfrontAssetHost.gzip_allowed_for_source?(source)
            key = "#{CloudfrontAssetHost.gzip_prefix}/" << CloudfrontAssetHost.key_for_path(path) << source
            result[key] = path
          end

          result
        end
      end

      def existing_keys
        @existing_keys ||= begin
          keys = []
          keys.concat bucket.keys('prefix' => CloudfrontAssetHost.key_prefix).map  { |key| key.name }
          keys.concat bucket.keys('prefix' => CloudfrontAssetHost.gzip_prefix).map { |key| key.name }
          keys
        end
      end

      def current_paths
        @current_paths ||= Dir.glob("#{Rails.public_path}/{#{ asset_dirs }}/**/*").reject { |path| File.directory?(path) }
      end

      def headers_for_path(extension, gzip = false)
        mime = ext_to_mime[extension] || 'application/octet-stream'
        headers = {
          'Content-Type' => mime,
          'Cache-Control' => "max-age=#{10.years.to_i}",
          'Expires' => 1.year.from_now.utc.to_s
        }
        headers['Content-Encoding'] = 'gzip' if gzip

        headers
      end

      def ext_to_mime
        @ext_to_mime ||= Hash[ *( YAML::load_file(File.join(File.dirname(__FILE__), "mime_types.yml")).collect { |k,vv| vv.collect{ |v| [v,k] } }.flatten ) ]
      end

      def bucket
        @bucket ||= s3.bucket(CloudfrontAssetHost.bucket)
      end

      def s3
        @s3 ||= RightAws::S3.new(config['access_key_id'], config['secret_access_key'])
      end

      def config
        @config ||= YAML::load_file(CloudfrontAssetHost.s3_config)
      end

      def asset_dirs
        @asset_dirs ||= CloudfrontAssetHost.asset_dirs
      end

    end

  end
end