module PivotalTracker
  class Publisher < Base
    class << self

      def run
        redis.psubscribe 'pivotal_tracker_bot/activity/*' do |on|
          on.psubscribe do |channel, _|
            logger.info "Publisher -- Subscribed to ##{channel}"
          end

          on.pmessage do |_, channel, message|
            logger.info "Publisher -- Message received \"#{message}\" from the channel ##{channel}"
            project_key = channel.split('/')[2]
            redis_key = "pivotal_tracker_bot/chat_id/#{project_key}"

            if redis_instance.exists(redis_key)
              chat_id = redis_instance.get(redis_key)
              telegram_bot.api.sendMessage(chat_id: chat_id, text: message, disable_web_page_preview: true)
            end
          end
        end
      rescue => error
        logger.fatal("Publisher -- Exception : #{error.message}\n#{error.backtrace.join("\n")}")
      end

      def redis_instance
        @redis_instance ||= Redis.new
      end

    end
  end
end