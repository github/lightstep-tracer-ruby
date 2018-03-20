require 'thread'
require 'net/http'
require 'lightstep/transport/base'

module LightStep
  module Transport
    # HTTPJSON is a transport that sends reports via HTTP in JSON format.
    # It is thread-safe.
    class HTTPJSON < Base
      LIGHTSTEP_HOST = "collector.lightstep.com"
      LIGHTSTEP_PORT = 443

      ENCRYPTION_TLS = 'tls'
      ENCRYPTION_NONE = 'none'

      # Initialize the transport
      # @param host [String] host of the domain to the endpoind to push data
      # @param port [Numeric] port on which to connect
      # @param verbose [Numeric] verbosity level. Right now 0-3 are supported
      # @param encryption [ENCRYPTION_TLS, ENCRYPTION_NONE] kind of encryption to use
      # @param access_token [String] access token for LightStep server
      # @return [HTTPJSON]
      def initialize(host: LIGHTSTEP_HOST, port: LIGHTSTEP_PORT, verbose: 0, encryption: ENCRYPTION_TLS, access_token:)
        @verbose = verbose

        raise Tracer::ConfigurationError, "access_token must be a string" unless String === access_token
        raise Tracer::ConfigurationError, "access_token cannot be blank"  if access_token.empty?
        @access_token = access_token

        # This mutex protects the use of our Net::HTTP instance which we
        # maintain as a long lived connection. While a Lightstep::Transport is
        # typically called only from within the reporting thread, there are
        # some situations where this can be bypassed (directly calling `flush`
        # for example)
        @mutex = Mutex.new

        @http = Net::HTTP.new(host, port)
        @http.use_ssl = encryption == ENCRYPTION_TLS
        @http.keep_alive_timeout = 5
      end

      # Queue a report for sending
      def report(report)
        p report if @verbose >= 3

        req = Net::HTTP::Post.new('/api/v0/reports')
        req['LightStep-Access-Token'] = @access_token
        req['Content-Type'] = 'application/json'
        req['Connection'] = 'keep-alive'

        req.body = report.to_json

        @mutex.synchronize do
          # Typically, keep-alive for Net:HTTP is handled inside a start block,
          # but that's awkward with our threading model. By starting it manually,
          # once, the TCP connection should remain open for multiple report calls.
          @http.start unless @http.started?

          res = @http.request(req)
        end

        puts res.to_s if @verbose >= 3

        nil
      end
    end
  end
end
