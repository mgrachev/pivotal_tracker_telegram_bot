require 'bundler/setup'
require 'redis'
require 'logger'
require 'telegram/bot'

module PivotalTracker
  class Base
    def self.redis
      $redis ||= Redis.new(timeout: 0)
    end

    def self.logger
      $logger ||= Logger.new(File.expand_path('../../log/pivotal_tracker_bot.log', __FILE__), 'weekly')
    end

    def self.telegram_bot
      $telegram_bot ||= Telegram::Bot::Client.new(ENV['TOKEN'], logger: logger)
    end
  end
end

require_relative 'pivotal_tracker/app'
require_relative 'pivotal_tracker/bot'
require_relative 'pivotal_tracker/publisher'
