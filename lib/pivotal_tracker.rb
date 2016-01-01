require 'bundler/setup'
require 'redis'
require 'logger'
require 'telegram/bot'
require 'airbrake'

# require 'dotenv' # Test only
# Dotenv.load

Airbrake.configure do |config|
  config.api_key = ENV['AIRBRAKE_KEY']
  config.host    = ENV['AIRBRAKE_HOST']
  config.port    = 80
  config.secure  = config.port == 443
  config.development_environments = []
end

module PivotalTracker
  class Base
    NAME = 'pivotal_tracker_bot'.freeze

    def self.redis
      $redis ||= Redis.new(timeout: 0)
    end

    def self.logger
      $logger ||= Logger.new(File.expand_path("../../log/#{NAME}.log", __FILE__), 'weekly')
    end

    def self.telegram_bot
      $telegram_bot ||= Telegram::Bot::Client.new(ENV['TOKEN'], logger: logger)
    end

    def self.send_to_errbit(exception, **kwargs)
      method_name = kwargs.delete(:method).to_s
      Airbrake.notify(
          exception,
          cgi_data:     ENV.to_hash,
          controller:   self,
          action:       method_name,
          parameters:   kwargs
      )
    end
  end
end
