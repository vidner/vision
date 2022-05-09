require "http/client"
require "json"
require "dns"
require "./request"

module Vision
  class Subdomain
    enum Engine
      AlienVault
      ThreadCrowd
      BufferOver
    end

    def initialize(domain : String)
      @domain = domain
      @engine = [Engine::AlienVault, Engine::ThreadCrowd, Engine::BufferOver]
    end

    def alienvault
      response = Request.get("https://otx.alienvault.com/api/v1/indicators/domain/#{@domain}/passive_dns")
      {@domain => JSON.parse(response.body)["passive_dns"].as_a.map { |x| x["hostname"].as_s }.uniq.to_a}
    rescue
      {@domain => [] of String}
    end

    def bufferover
      response = Request.get("https://dns.bufferover.run/dns?q=.#{@domain}")
      rdns = JSON.parse(response.body)["RDNS"].as_a.map { |x| x.as_s.split(",")[1] }.uniq.to_a

      fdns = JSON.parse(response.body)["FDNS_A"].as_a.map { |x| x.as_s.split(",")[1] }.uniq.to_a
      {@domain => rdns.concat(fdns).uniq}
    rescue
      {@domain => [] of String}
    end

    def threadcrowd
      response = Request.get("https://www.threatcrowd.org/searchApi/v2/domain/report/?domain=#{@domain}")
      {@domain => JSON.parse(response.body)["subdomains"].as_a.map { |x| x.as_s }.uniq.to_a}
    rescue
      {@domain => [] of String}
    end

    def fdns(domain)
      resolver = DNS::Resolver.new
      response = resolver.query(domain, DNS::RecordType::A)
      response.answers.map { |x| x.data.to_s }.join(",")
    rescue
      ""
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
        result.concat(channel.receive[@domain])
      end
      {@domain => result.uniq.map { |x| {"hostname" => x, "address" => fdns(x)} }}
    end

    def choose_engine(engine : Engine)
      case engine
      when Engine::AlienVault
        alienvault
      when Engine::ThreadCrowd
        threadcrowd
      when Engine::BufferOver
        bufferover
      else
        raise "Invalid engine"
      end
    end
  end
end
