require_relative 'main'
require 'telegram/bot'

$redis.psubscribe 'pivotal_tracker_bot/activity/*' do |on|
  on.psubscribe do |channel, subscriptions|
    puts "Subscribed to ##{channel} (#{subscriptions} subscriptions)"
  end

  on.pmessage do |_, channel, message|
    project_key = channel.split('/')[2]
    redis_key = "pivotal_tracker_bot/chat_id/#{project_key}"

    redis2 = Redis.new
    if redis2.exists(redis_key)
      chat_id = redis2.get(redis_key)

      bot = Telegram::Bot::Client.new(ENV['TOKEN'])
      bot.api.sendMessage(chat_id: chat_id, text: message)
    end
  end
end