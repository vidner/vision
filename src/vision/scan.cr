require "ipaddress"
require "./service"
require "./subdomain"
require "./view"

module Vision
  class Scan
    def initialize(target : String, complete : Bool, engine : View::Engine, channel_id : Discord::Snowflake = Discord::Snowflake.new(0))
      @target = target
      @complete = complete
      @view = View.new(engine, channel_id)
    end

    def get_prefix
      target = IPAddress.new @target
      target.prefix.to_s
    rescue
      # TODO: handle if target is not an ip/subnets (this just a temporary hack)
      "1337"
    end

    def run
      prefix = get_prefix.to_u32

      if prefix > 23 && prefix < 32
        scan_subnet(@target)
      end

      if prefix == 32
        scan_ip(@target)
      end

      if prefix == 1337
        scan_domain(@target)
      end
    end

    def format_service_result(ip, ports)
      result = ""
      ports.each do |port|
        result += "#{ip}:#{port}\n"
      end
      @view.render(result)
    end

    def format_subdomain_result(subdomains)
      subdomains.each do |subdomain|
        hostname = subdomain["hostname"]
        ips = subdomain["address"].split(",")
        ips.delete("")
        @view.render("#{hostname} #{ips}")
        if @complete
          channel = Channel(String).new
          ips.each do |ip|
            spawn do
              scan_ip ip
              channel.send("done")
            end
          end
          ips.each do |ip|
            channel.receive
          end
          @view.render("")
        end
      end
    end

    def scan_subnet(subnet)
      ips = IPAddress.new subnet
      channel = Channel(String).new

      ips.each do |ip|
        spawn do
          service = Service.new ip.to_s
          result = service.all
          format_service_result(ip.to_s, result[ip.to_s])
          channel.send("done")
        end
      end
      ips.each do |ip|
        result = channel.receive
      end
    end

    def scan_ip(ip)
      service = Service.new ip
      result = service.all
      format_service_result(ip, result[ip])
    end

    def scan_domain(domain)
      subdomain = Subdomain.new domain
      result = subdomain.all
      format_subdomain_result(result[domain])
    end
  end
end
