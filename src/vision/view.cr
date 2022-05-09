require "discordcr"
require "./discord"

module Vision
  class View
    enum Engine
      StdOut
      Discord
      Slack # TODO Add Slack support
    end

    def initialize(type : Engine, channel_id : Discord::Snowflake)
      @type = type
      @channel_id = channel_id
    end

    def stdout(str)
      puts str
    end

    def render(str)
      if @type == Engine::StdOut
        stdout(str)
      end

      if @type == Engine::Discord && str != ""
        DiscordBot.send_result(@channel_id, str)
      end
    end
  end
end
