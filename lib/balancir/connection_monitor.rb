require 'celluloid'

module Balancir
  # Watches dead connections to see if they come back to life.
  class ConnectionMonitor
    include Celluloid
    attr_accessor :polling_interval_seconds, :ping_path, :revive_threshold
    attr_reader :distributor, :responses, :timer

    def initialize(distributor, opts)
      @distributor = distributor
      @polling_interval_seconds = opts.fetch(:polling_interval_seconds)
      @ping_path = opts.fetch(:ping_path)
      @revive_threshold = opts.fetch(:revive_threshold)
      @responses = {}
    end

    def add_connector(connector)
      raise ArgumentError unless connector.respond_to?(:get)
      @responses[connector] = []
      @timer = every(@polling_interval_seconds) { poll }
    end

    def fire
      @timer.fire
    end

    def poll
      @responses.keys do |c|
        response = c.get(@ping_path)
        tally_response(c, response)
        if revive_threshold_met?(c)
          @distributor.add_connector(c, 50)
        end
      end
    end

    def tally_response(connector, response)
      @responses[connector] << response.successful?
      while @responses[connector].length > @revive_threshold.last
        @responses[connector].shift
      end
    end

    def revive_threshold_met?(connector)
      @responses[connector].count(true) >= @revive_threshold.first
    end

    def connectors
      @responses.keys
    end
  end
end
