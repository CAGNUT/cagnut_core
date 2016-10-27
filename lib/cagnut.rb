require 'tilt'
require 'active_support'
require 'active_support/core_ext'
require 'fileutils'
require 'pathname'
require 'cagnut/version'
require 'cagnut/configuration'
require 'cagnut/job_manage'

Tilt.register_lazy :StringTemplate, 'tilt/string', 'sh'

module Cagnut
  autoload :Base, 'cagnut/base'

  class << self
    attr_writer :environment

    def root
      ::Pathname.new File.expand_path '../..', __FILE__
    end

    # Job names can contain up to 4094 characters.
    def prefix_name
      "CAGNUT_#{Time.now.strftime('%Y%m%d%H%M%S')}"
    end

    def environment
      @environment ||= 'development'
    end

    def load_config config_name, config_options
      Cagnut::Configuration.config = Cagnut::Configuration.load_config config_name, config_options
    end

  end
end
