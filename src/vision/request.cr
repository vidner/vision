require "http/client"
require "uri"

module Vision
  class Request
    def self.get(url)
      uri = URI.parse(url)
      client = HTTP::Client.new(uri)
      client.connect_timeout = 5
      begin
        response = client.get(uri.path)
        response
      end
    end
  end
end
