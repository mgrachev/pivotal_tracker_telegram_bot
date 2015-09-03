require 'bundler/setup'
require 'dotenv'
require 'telegram/bot'
require 'redis'

Dotenv.load
$redis = Redis.new

bot_name = 'Pivotal Tracker Bot'.freeze
bot_help = <<-HELP
  Initially, the need to integrate the bot with pivotal tracker.
  See: https://github.com/mgrachev/pivotal_tracker_telegram_bot

  Available commands:

  /start  - Start a #{bot_name}
  /track  - Tracking project
  /stop   - Stop tracking project
  /help   - Show hint
HELP

track_argument_error = 'You must specify the project ID and Project Name.\n Example: /track 1234 Ruby'

Telegram::Bot::Client.run(ENV['TOKEN']) do |bot|
  bot.listen do |message|
    case message.text
    when '/start'
      bot.api.sendMessage(chat_id: message.chat.id, text: "Hello! I'm #{bot_name}")
    when /^\/track/
      args = message.text.split(' ')

      if args.length < 3
        bot.api.sendMessage(chat_id: message.chat.id, text: track_argument_error)
        next
      end

      project_id, project_name = args[1..-1]
      $redis.set("pivotal_tracker_bot/chat_id/#{project_id}_#{project_name}", message.chat.id)
      # To stop tracking
      $redis.set("pivotal_tracker_bot/project_key/#{message.chat.id}", "#{project_id}_#{project_name}")

      bot.api.sendMessage(chat_id: message.chat.id, text: "Start tracking project #{project_name}")
    when '/stop'
      project_key   = $redis.get("pivotal_tracker_bot/project_key/#{message.chat.id}")
      project_name  = project_key.split('_')[1]

      $redis.del("pivotal_tracker_bot/chat_id/#{project_key}")
      $redis.del("pivotal_tracker_bot/project_key/#{message.chat.id}")

      bot.api.sendMessage(chat_id: message.chat.id, text: "Stop tracking project #{project_name}")
    when '/help'
      bot.api.sendMessage(chat_id: message.chat.id, text: bot_help)
    end
  end
end

