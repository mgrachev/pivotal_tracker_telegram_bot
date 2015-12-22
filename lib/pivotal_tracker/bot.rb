module PivotalTracker
  class Bot < Base
    NAME = 'Pivotal Tracker Bot'.freeze
    HELP = <<-HELP
    Initially, the need to integrate the bot with pivotal tracker.
    See: https://github.com/mgrachev/pivotal_tracker_telegram_bot

    Support: #{ENV['SUPPORT_EMAIL']}

    Available commands:

    /start  - Start a #{NAME}
    /track  - Tracking project
    /stop   - Stop tracking project
    /help   - Show hint
    HELP

    TRACK_ARGUMENT_ERROR = "You must specify the project ID and Project Name.\n Example: /track 1234 Ruby".freeze

    def self.run
      telegram_bot.run do |bot|
        bot.listen do |message|
          case message.text
          when %r{^\/start}
            bot.api.sendMessage(chat_id: message.chat.id, text: "Hello! I'm #{NAME}")
          # TODO: Disable tracking multiple projects
          when %r{^\/track}
            args = message.text.split(' ')

            if args.length < 3
              bot.api.sendMessage(chat_id: message.chat.id, text: TRACK_ARGUMENT_ERROR)
              next
            end

            project_id, project_name = args[1..-1]
            redis.set("pivotal_tracker_bot/chat_id/#{project_id}_#{project_name}", message.chat.id)
            # To stop tracking
            redis.set("pivotal_tracker_bot/project_key/#{message.chat.id}", "#{project_id}_#{project_name}")

            bot.api.sendMessage(chat_id: message.chat.id, text: "Start tracking project #{project_name}")
          when %r{^\/stop}
            redis_key = "pivotal_tracker_bot/project_key/#{message.chat.id}"

            unless redis.exists(redis_key)
              bot.api.sendMessage(chat_id: message.chat.id, text: 'No track projects')
              next
            end

            project_key   = redis.get(redis_key)
            project_name  = project_key.split('_')[1]

            redis.del("pivotal_tracker_bot/chat_id/#{project_key}")
            redis.del("pivotal_tracker_bot/project_key/#{message.chat.id}")

            bot.api.sendMessage(chat_id: message.chat.id, text: "Stop tracking project #{project_name}")
          when %r{^\/help}
            bot.api.sendMessage(chat_id: message.chat.id, text: HELP)
          end
        end
      end
    rescue => error
      logger.fatal("Bot -- Exception : #{error.message}\n#{error.backtrace.join("\n")}")
    end
  end
end
