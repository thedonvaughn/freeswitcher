require 'spec/helper'
require "fsr/listener"
require "fsr/listener/inbound"
gem "tmm1-em-spec"
require "em/spec"

# Bare class to use for testing
class InboundListener < FSR::Listener::Inbound
  attr_accessor :test_event

  def initialize(*args)
    super(*args)
    @test_event = nil
  end

  def on_event(event)
    recvd_event << event
  end

  def recvd_event
    @recvd_event ||= []
  end

end

class InboundListener2 < FSR::Listener::Inbound
  attr_accessor :test_event

  def initialize(*args)
    super(*args)
    @test_event = nil
  end

  def before_session
    add_event(:TEST_EVENT) {|event| recvd_event << event}
  end

  def recvd_event
    @recvd_event ||= []
  end

end

describe "Testing FSR::Listener::Inbound" do

  it "defines #post_init" do
    FSR::Listener::Inbound.method_defined?(:post_init).should == true
  end

  it "adds and deletes hooks" do
    FSL::Inbound.add_event_hook(:CHANNEL_CREATE) {|event| puts event.inspect }
    FSL::Inbound::HOOKS.size.should == 1
    FSL::Inbound.del_event_hook(:CHANNEL_CREATE)
    FSL::Inbound::HOOKS.size.should == 0
  end

end

EM.describe InboundListener do

  before do
    @listener = InboundListener.new("test", {:auth => 'SecretPassword'})
    @listener2 = InboundListener2.new("test", {:auth => 'SecretPassword'})
  end

  should "be able to receive an event and call the on_event callback method" do
    @listener.receive_data("Content-Length: 22\n\nEvent-Name: test_event\n\n")
    @listener.recvd_event.first.content[:event_name].should.equal "test_event"
    done
  end

  should "be able to add custom event hooks in the pre_session" do
    @listener2.receive_data("Content-Length: 22\n\nEvent-Name: TEST_EVENT\n\n")
    @listener2.recvd_event.first.content[:event_name].should.equal "TEST_EVENT"
    done
  end

  should "be able to add custom event hooks" do
    FSL::Inbound.add_event_hook(:HANGUP_EVENT) {|event| @listener.test_event = event}
    @listener.test_event.should.equal nil
    @listener.receive_data("Content-Length: 24\n\nEvent-Name: HANGUP_EVENT\n\n")
    @listener.test_event.content[:event_name].should.equal "HANGUP_EVENT"
    done
  end

  should "be able to change Freeswitch auth" do
    @listener.auth.should.equal 'SecretPassword'
    done
  end

end
