module PivotalTracker
  class Bot < Base
    BOT_NAME = 'Pivotal Tracker Bot'.freeze
    HELP = <<HELP
Initially, the need to integrate the bot with Pivotal Tracker.
See: https://github.com/mgrachev/pivotal_tracker_telegram_bot

Available commands:
/start - Start a #{BOT_NAME}
/track - Tracking project
/stop  - Stop tracking project
/help  - Show hint

Support: #{ENV['SUPPORT_EMAIL']}
HELP

    TRACK_ARGUMENT_ERROR = "You must specify the project ID and Project Name.\n Example: /track 1234567 My Sample Project".freeze

    def self.run
      telegram_bot.run do |bot|
        bot.listen do |message|
          chat_id = message.chat.id

          case message.text
          when %r{^\/start}
            bot.api.sendMessage(chat_id: chat_id, text: "Hello! I'm #{BOT_NAME}")

          when %r{^\/help}
            bot.api.sendMessage(chat_id: chat_id, text: HELP, disable_web_page_preview: true)

          when %r{^\/track}
            # TODO: Disable tracking multiple projects
            args = message.text.split(' ')

            if args.length < 3
              bot.api.sendMessage(chat_id: chat_id, text: TRACK_ARGUMENT_ERROR)
              next
            end

            project_id    = args[1]
            project_name  = args[2..-1].join('_')
            project_key   = "#{project_id}_#{project_name}"

            redis.set("#{NAME}/chat_id/#{project_key}", chat_id)
            # To stop tracking project
            redis.set("#{NAME}/project_key/#{chat_id}", project_key)

            bot.api.sendMessage(chat_id: chat_id, text: "Start tracking project \"#{project_name.tr('_', ' ')}\"")

          when %r{^\/stop}
            redis_key = "#{NAME}/project_key/#{chat_id}"

            unless redis.exists(redis_key)
              bot.api.sendMessage(chat_id: chat_id, text: 'No track projects')
              next
            end

            project_key   = redis.get(redis_key)
            project_name  = project_key.split('_')[1]

            redis.del("#{NAME}/chat_id/#{project_key}")
            redis.del("#{NAME}/project_key/#{chat_id}")

            bot.api.sendMessage(chat_id: chat_id, text: "Stop tracking project #{project_name}")
          end
        end
      end
    rescue => error
      logger.fatal("Bot -- Exception : #{error.message}\n#{error.backtrace.join("\n")}")
    end
  end
end
