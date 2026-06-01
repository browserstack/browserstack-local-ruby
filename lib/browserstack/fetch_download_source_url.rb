require 'net/http'
require 'net/https'
require 'json'
require 'openssl'
require 'browserstack/localexception'

module BrowserStack
  module FetchDownloadSourceUrl
    BS_HOST = 'local.browserstack.com'.freeze
    ENDPOINT_PATH = '/binary/api/v1/endpoint'.freeze

    def self.call(auth_token:, user_agent:, fallback: false, error_message: nil,
                  proxy_host: nil, proxy_port: nil)
      uri = URI::HTTPS.build(host: BS_HOST, path: ENDPOINT_PATH)

      body = { 'auth_token' => auth_token }
      body['error_message'] = error_message if fallback && error_message

      http_class = if proxy_host && proxy_port
                     Net::HTTP::Proxy(proxy_host, proxy_port.to_i)
                   else
                     Net::HTTP
                   end

      http = http_class.new(uri.host, uri.port)
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_PEER

      req = Net::HTTP::Post.new(uri.request_uri)
      req['Content-Type'] = 'application/json'
      req['User-Agent'] = user_agent
      req['X-Local-Fallback-Cloudflare'] = 'true' if fallback
      req.body = JSON.dump(body)

      res = http.request(req)

      begin
        parsed = JSON.parse(res.body.to_s)
      rescue JSON::ParserError => e
        raise BrowserStack::LocalException.new(
          "Failed to parse binary endpoint API response (HTTP #{res.code}): #{e.message}"
        )
      end

      if parsed.is_a?(Hash) && parsed['error']
        raise BrowserStack::LocalException.new(
          "Binary endpoint API returned error: #{parsed['error']}"
        )
      end

      endpoint = parsed.is_a?(Hash) ? parsed.dig('data', 'endpoint') : nil
      if endpoint.nil? || endpoint.to_s.empty?
        raise BrowserStack::LocalException.new(
          "Binary endpoint API returned no endpoint (HTTP #{res.code})"
        )
      end

      endpoint
    end
  end
end
