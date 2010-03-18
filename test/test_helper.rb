require 'test/unit'
require 'rubygems'

require 'action_controller'
require 'right_aws'

require 'shoulda'
require 'mocha'
begin require 'redgreen'; rescue LoadError; end
begin require 'turn'; rescue LoadError; end

RAILS_ROOT = File.expand_path(File.join(File.dirname(__FILE__), 'app'))

module Rails
  class << self
    def root
      RAILS_ROOT
    end

    def public_path
      File.join(RAILS_ROOT, 'public')
    end
  end
end

require File.join(File.dirname(__FILE__), '..', 'lib', 'cloudfront_asset_host')
