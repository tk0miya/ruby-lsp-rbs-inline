# frozen_string_literal: true

require "ruby_lsp/rbs/inline/logger"

RSpec.describe RubyLsp::Rbs::Inline::Logger do
  describe "#info" do
    subject { logger.info(message) }

    let(:logger) { described_class.new(message_queue) }
    let(:message_queue) { Thread::Queue.new }
    let(:message) { "Test log message" }

    it "Notification object is sent to message queue" do
      subject
      log = message_queue.pop
      expect(log).to be_a(RubyLsp::Notification)
      expect(log.params.message).to eq "rbs-inline: #{message}"
    end
  end
end
