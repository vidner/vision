require "dotenv"
require "discordcr"
require "./scan"
require "./view"

module Vision
  class DiscordBot
    PREFIX = "!"
    if !ENV.has_key?("DISCORD_TOKEN") || !ENV.has_key?("DISCORD_CLIENT_ID")
      Dotenv.load
    end
    DISCORD_TOKEN     = ENV["DISCORD_TOKEN"]
    DISCORD_CLIENT_ID = ENV["DISCORD_CLIENT_ID"].to_u64
    CLIENT            = Discord::Client.new(token: DISCORD_TOKEN, client_id: DISCORD_CLIENT_ID)

    def initialize
      @client = CLIENT
    end

    def self.create_block_message(msg)
      msg = "```#{msg}```"
      msg
    end

    def self.send_result(channel_id, result)
      client = CLIENT
      client.create_message(channel_id, create_block_message(result))
    end

    def get_help_message
      msg = "```\n"
      msg += "!scan hackerone.com (subdomain enumeration)\n"
      msg += "!scan 13.33.33.37 (port scan)\n"
      msg += "!scan deep hackerone.com (subdomain enumeration + port scan)\n"
      msg += "!scan 13.33.33.37/29 (subnet port scan - for now only support > /24)\n"
      msg += "!scan deep 13.33.33.37/25,hackerone.com (everything combine together)\n"
      msg += "!about (show about)\n"
      msg += "!help (show help)\n"
      msg += "\nPS: subnet scan mostly trigger discord rate limiter, restart the bot to fix it\n"
      msg += "```\n"
      msg
    end

    def run
      engine = View::Engine::Discord
      client = @client
      client.on_message_create do |payload|
        command = payload.content

        case command
        when PREFIX + "help"
          client.create_message(client.create_dm(payload.author.id).id, get_help_message)
        when PREFIX + "about"
          block = "> Bot developed by vidner"
          client.create_message(payload.channel_id, block)
        when .starts_with? PREFIX + "scan"
          arguments = command.split(' ')[1..-1]

          if arguments.empty?
            client.create_message(payload.channel_id, "Please provide a target to scan")
          else
            is_complete = false
            if arguments.includes? "deep"
              is_complete = true
            end

            targets = arguments.last.split(',')
            channel = Channel(String).new

            targets.each do |x|
              spawn do
                scan = Scan.new(x, is_complete, engine, payload.channel_id)
                scan.run
                channel.send("done")
              end
            end

            targets.each do |x|
              channel.receive
            end
          end
        else
        end
      end

      client.run
    end
  end
end
