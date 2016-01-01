require_relative '../pivotal_tracker'

module PivotalTracker
  class Publisher < Base
    class << self
      attr_reader :chat_id, :project_key
    end

    def self.run
      redis.psubscribe "#{NAME}/activity/*" do |on|
        on.psubscribe do |channel, _|
          logger.info "Publisher -- Subscribed to ##{channel}"
        end

        on.pmessage do |_, channel, message|
          logger.info "Publisher -- Message received \"#{message}\" from the channel ##{channel}"
          @project_key = channel.split('/')[2]
          redis_key = "#{NAME}/chat_id/#{project_key}"

          if redis_instance.exists(redis_key)
            @chat_id = redis_instance.get(redis_key)
            telegram_bot.api.sendMessage(chat_id: chat_id, text: message, disable_web_page_preview: true)
          end
        end
      end
    rescue => e
      send_to_errbit(e, method: __callee__, project_key: project_key, chat_id: chat_id)
      retry
    end

    def self.redis_instance
      @redis_instance ||= Redis.new
    end
  end
end
