require 'net/http'
require 'net/https'
require 'json'
require 'openssl'
require 'browserstack/localexception'

module BrowserStack
  module FetchDownloadSourceUrl
    BS_HOST = 'local.browserstack.com'.freeze
    ENDPOINT_PATH = '/binary/api/v1/endpoint'.freeze
    ALLOWED_DOWNLOAD_HOSTS = ['browserstack.com'].freeze
    ALLOWED_DOWNLOAD_HOST_SUFFIXES = ['.browserstack.com'].freeze

    # Each guard below covers a case the final host-equals check does not:
    #   - nil/empty URL: URI.parse(nil) raises TypeError before the rescue can catch it.
    #   - URI::InvalidURIError: convert raw Ruby error into BrowserStack::LocalException for the public contract.
    #   - HTTPS check: allowlist matches host only; without this, http://browserstack.com would pass.
    #   - nil/empty host: uri.host is nil for URIs like https:///foo, which would crash on downcase.
    def self.validate_source_url(url)
      if url.nil? || url.to_s.empty?
        raise BrowserStack::LocalException.new('Refusing binary download: empty source URL')
      end
      uri = begin
        URI.parse(url)
      rescue URI::InvalidURIError
        raise BrowserStack::LocalException.new('Refusing binary download: malformed source URL')
      end
      unless uri.scheme == 'https'
        raise BrowserStack::LocalException.new('Refusing binary download from non-HTTPS source URL')
      end
      host = (uri.host || '').downcase
      if host.empty?
        raise BrowserStack::LocalException.new('Refusing binary download: source URL has no host')
      end
      return url if ALLOWED_DOWNLOAD_HOSTS.include?(host)
      return url if ALLOWED_DOWNLOAD_HOST_SUFFIXES.any? { |suffix| host.end_with?(suffix) }
      raise BrowserStack::LocalException.new("Refusing binary download: host '#{host}' is not in the allowed host list")
    end

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
      http.open_timeout = 10
      http.read_timeout = 15

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

      validate_source_url(endpoint)
    end
  end
end
