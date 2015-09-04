require_relative 'main'
require 'telegram/bot'

other_redis = Redis.new
bot = Telegram::Bot::Client.new(ENV['TOKEN'])

$redis.psubscribe 'pivotal_tracker_bot/activity/*' do |on|
  on.psubscribe do |channel, subscriptions|
    puts "Subscribed to ##{channel} (#{subscriptions} subscriptions)"
  end

  on.pmessage do |_, channel, message|
    project_key = channel.split('/')[2]
    redis_key = "pivotal_tracker_bot/chat_id/#{project_key}"

    if other_redis.exists(redis_key)
      chat_id = other_redis.get(redis_key)
      bot.api.sendMessage(chat_id: chat_id, text: message, disable_web_page_preview: true)
    end
  end
end