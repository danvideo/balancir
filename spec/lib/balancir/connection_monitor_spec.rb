require 'spec_helper'
require 'balancir/connection_monitor'
require 'balancir/connector'
require 'balancir/distributor'

describe Balancir::ConnectionMonitor do
  include ResponseUtils
  MONITOR_CONFIG = { :polling_interval_seconds => 5,
                     :ping_path => "/ping",
                     :revive_threshold => [10,10] }

  before do
    @distributor = Balancir::Distributor.new
    @monitor = Balancir::ConnectionMonitor.new(@distributor, MONITOR_CONFIG)
  end

  describe '#initialize' do
    it 'sets a polling interval' do
      @monitor.polling_interval_seconds.should eq(5)
    end

    it 'sets a ping path' do
      @monitor.ping_path.should eq('/ping')
    end

    it 'sets a revive threshold' do
      @monitor.revive_threshold.should eq([10,10])
    end
  end

  describe '#add_connector' do
    before do
      @connector = Balancir::Connector.new(CONNECTOR_CONFIG)
      @monitor.add_connector(@connector)
    end

    it 'records the connection addred' do
      @monitor.connectors.should have(1).item
    end

    it 'starts a timer' do
      @monitor.timer.interval.should eq(MONITOR_CONFIG[:polling_interval_seconds])
    end
  end

  describe 'timer' do
    before do
      @connector = Balancir::Connector.new(CONNECTOR_CONFIG)
      @monitor.add_connector(@connector)
    end

    it 'calls #poll when triggered' do
      # Celluloid#wrapped_object lets rspec expectations work with cellulooid proxying
      @monitor.wrapped_object.should_receive(:poll)
      @monitor.fire
    end

    it 'repeats' do
      @monitor.timer.recurring.should be_true
      @monitor.fire
    end
  end

  # Can we prove that timer events won't pile up if polling is low?

  describe '#revive_threshold_met?' do
    before do
      @connector = Balancir::Connector.new(CONNECTOR_CONFIG)
      @monitor.add_connector(@connector)
    end

    context 'with a string of failures' do
      before do
        @response = failed_response
      end

      it 'always returns false' do
        20.times do
          @monitor.tally_response(@connector, @response)
          @monitor.revive_threshold_met?(@connector).should be_false
        end
      end
    end

    context 'with a working connecton' do
      before do
        @response = successful_response
      end

      it 'returns false before threshold is met' do
        9.times do
          @monitor.tally_response(@connector, @response)
          @monitor.revive_threshold_met?(@connector).should be_false
        end
      end

      it 'returns true once threshold is met' do
        10.times do
          @monitor.tally_response(@connector, @response)
        end
        @monitor.revive_threshold_met?(@connector).should be_true
      end
    end

    context 'with an intermittent connecton' do
      before do
        @monitor.revive_threshold = [7,10]
      end

      it 'returns false with enough successes but not enough in a row' do
        responses = [successful_response, successful_response, successful_response,
                     failed_response, failed_response]
        responses.cycle(4) do |r|
          @monitor.tally_response(@connector, r)
          @monitor.revive_threshold_met?(@connector).should be_false
        end
      end

      it 'returns true when the successes proportion is actually met' do
        responses = [successful_response, successful_response, successful_response,
                     failed_response]
        responses.cycle(3) do |r|
          @monitor.tally_response(@connector, r)
        end
        @monitor.revive_threshold_met?(@connector).should be_true
      end
    end
  end

  describe '#poll' do
    before do
      @connector_a = Balancir::Connector.new(:url => 'https://first-environment.mycompany.com',
                                             :failure_ratio => [5,10])
      @connector_b = Balancir::Connector.new(:url =>'https://second-environment.mycompany.com',
                                             :failure_ratio => [5,10])
      @monitor.add_connector(@connector_a)
      @monitor.add_connector(@connector_b)
    end

    it 'tries each connection' do
      @connector_a.should_receive(:get).with(PING_PATH).and_return(successful_response)
      @connector_b.should_receive(:get).with(PING_PATH).and_return(successful_response)
      @monitor.fire
    end

    context 'with one working connection and one busted' do
      before do
        @connector_a.stub(:get).with(PING_PATH).and_return(successful_response)
        @connector_b.stub(:get).with(PING_PATH).and_return(failed_response)
      end

      it 'does reactivate the connection before the revive threshold is reached' do
        @monitor.should_not_receive(:reactivate)

        9.times do
          @monitor.fire
        end
      end

      it 'reactivates the connection' do
        @distributor.active_connectors.should be_empty
        @monitor.wrapped_object.should_receive(:reactivate)
        10.times do
          @monitor.fire
        end
      end
    end

    describe '#reactivate' do
      before do
        @connector = Balancir::Connector.new(CONNECTOR_CONFIG)
        @monitor.add_connector(@connector)
        @monitor.reactivate(@connector)
      end

      it 'notifies the distributor' do
        @distributor.active_connectors.should include(@connector)
      end

      it 'removes the connection from the monitored list' do
        @monitor.connectors.should_not include(@connector)
      end
    end
  end
end

  # timer methods:
  [:<,
   :<=,
   :>,
   :>=,
   :between?,
   :call,
   :cancel,
   :fire,
   :interval,
   :recurring,
   :reset,
   :time]
