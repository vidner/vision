require "http/client"
require "json"
require "./request"

module Vision
  class Service
    enum Engine
      InternetDB
    end

    def initialize(ip : String)
      @ip = ip
      @engine = [Engine::InternetDB]
    end

    def internetdb
      response = Request.get("https://internetdb.shodan.io/#{@ip}")
      {@ip => JSON.parse(response.body)["ports"].as_a.map { |x| x.to_s }.to_a}
    rescue
      {@ip => [] of String}
    end

    def all
      channel = Channel(Hash(String, Array(String))).new
      result = Array(String).new
      @engine.each do |engine|
        spawn do
          channel.send(choose_engine(engine))
        end
      end
      @engine.each do
        result.concat(channel.receive[@ip])
      end
      {@ip => result.uniq}
    end

    def choose_engine(engine : Engine)
      case engine
      when Engine::InternetDB
        internetdb
      else
        raise "Invalid engine"
      end
    end
  end
end
