require_relative 'main'

redis_instance = Redis.new

begin
  $redis.psubscribe 'pivotal_tracker_bot/activity/*' do |on|
    on.psubscribe do |channel, _|
      $publisher_logger.info "Subscribed to ##{channel}"
    end

    on.pmessage do |_, channel, message|
      $publisher_logger.info "Message received \"#{message}\" from the channel ##{channel}"
      project_key = channel.split('/')[2]
      redis_key = "pivotal_tracker_bot/chat_id/#{project_key}"

      if redis_instance.exists(redis_key)
        chat_id = redis_instance.get(redis_key)
        $telegram_bot.api.sendMessage(chat_id: chat_id, text: message, disable_web_page_preview: true)
      end
    end
  end
rescue => error
  $publisher_logger.fatal(error)
end