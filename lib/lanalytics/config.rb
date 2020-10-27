# frozen_string_literal: true

require 'active_support/configurable'
require 'erb'
require 'yaml'

module Lanalytics
  class Configuration < ActiveSupport::Configurable::Configuration
    def initialize(&init_block)
      super()

      @init = init_block

      reload!
    end

    def reload!
      clear
      @init.call(self)
    end

    def load_file(filename)
      merge YAML.safe_load ERB.new(::File.read(filename)).result
    end

    def merge(opts)
      opts.each do |k, v|
        send :"#{k}=", v
      end

      compile_methods!
    end
  end

  module Config
    def self.locations=(locations)
      @locations = locations.select {|file| ::File.exist? file }
    end

    def self.locations
      @locations ||= []
    end
  end

  def self.config
    @config ||= Configuration.new do |instance|
      Config.locations.each do |location|
        instance.load_file location
      end
    end
  end
end
