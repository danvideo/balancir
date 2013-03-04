require 'spec_helper'
require 'balancir/distributor'
require 'balancir/connector'

describe Balancir::Distributor do
  before do
    @connector = Balancir::Connector.new(CONNECTOR_CONFIG)
    @distributor = Balancir::Distributor.new
    @response = double(:status => 200)
  end

  context 'with a single connector' do
    before do
      @connector = Balancir::Connector.new(CONNECTOR_CONFIG)
      @distributor = Balancir::Distributor.new
      @distributor.add_connector(@connector, 100)
      @response = double(:status => 200)
    end

    describe 'message passing' do
      it 'passes on calls to #get' do
        @connector.should_receive(:get).and_return(@response)
        @distributor.get(SOME_PATH)
      end

      pending "other http methods" do
        it 'passes on calls to #post'
        it 'passes on calls to #put'
        it 'passes on calls to #delete'
      end
    end
  end

  describe 'with a single, failed connector' do
    before do
      @distributor.failed_connectors = [@connector]
      @distributor.active_connectors = []
    end

    it 'raises Balancir::NoConnectorsAvailable when called' do
      expect { @distributor.get(SOME_PATH) }.to raise_error(Balancir::Distributor::NoConnectorsAvailable)
    end

    it 'tests the failed connector'
    it 'reenables the failed connecor when it comes back'
  end

  context 'with two well-behaved connectors' do
    before do
      @connector_a = Balancir::Connector.new(:url => 'https://first-cluster.mycompany.com',
                                             :failure_ratio => [5,10])
      @connector_b = Balancir::Connector.new(:url =>'https://second-cluster.mycompany.com',
                                             :failure_ratio => [5,10])
      @distributor.add_connector(@connector_a, 50)
      @distributor.add_connector(@connector_b, 50)
    end

    it 'distributes calls between them' do
      @connector_a.should_receive(:get).twice.and_return(@response)
      @connector_b.should_receive(:get).twice.and_return(@response)

      4.times do
        @distributor.get(SOME_PATH)
      end
    end

    describe 'distribute load' do
      it 'determines the percentage of load distribution for each the connectors' do
        numbers = 10.times.map{ rand(100) }
        @connector
      end
    end
  end

  describe 'with two connectors, one well-behaved, one not' do
    it 'tolerates occasional errors'
    it 're-enables a failed connector which resumes working'

    before do
      @connector_a = Balancir::Connector.new(:url => 'https://first-cluster.mycompany.com',
                                             :failure_ratio => [5,10])
      @connector_b = Balancir::Connector.new(:url =>'https://second-cluster.mycompany.com',
                                             :failure_ratio => [5,10])
      @distributor.active_connectors = [@connector_a]
      @distributor.failed_connectors = [@connector_b]
    end

    it 'distributes all calls to the good connector' do
      @connector_a.should_receive(:get).exactly(4).and_return(@response)
      @connector_b.should_not_receive(:get)

      4.times do
        @distributor.get(SOME_PATH)
      end
    end

    it 'disables a failing connector' do
      pending
      @connector_b.failure_ratio = [10, 10]
    end
  end
end
