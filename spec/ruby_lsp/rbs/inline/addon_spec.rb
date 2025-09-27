# frozen_string_literal: true

require "language_server-protocol"
require "ruby_lsp/global_state"
require "ruby_lsp/rbs/inline/addon"
require "tempfile"

include LanguageServer::Protocol::Constant # rubocop:disable Style/MixinUsage

RSpec.describe RubyLsp::Rbs::Inline::Addon do
  describe "#did_change_watched_files" do
    subject { addon.workspace_did_change_watched_files(changes) }

    before { addon.activate(global_state, message_queue) }

    after { workspace_path.rmtree }

    let(:addon) { described_class.new }
    let(:global_state) { instance_double(RubyLsp::GlobalState, workspace_path:) }
    let(:message_queue) { Thread::Queue.new }
    let(:workspace_path) { Pathname.new(Dir.mktmpdir) }

    context "when file creation is received" do
      before do
        rb_path.parent.mkpath
        rb_path.write("class File; end")
      end

      let(:changes) do
        [
          { uri: "file:///#{workspace_path}/path/to/file.rb",
            type: FileChangeType::CREATED }
        ]
      end
      let(:rb_path) { workspace_path / "path/to/file.rb" }
      let(:rbs_path) { workspace_path / "sig/generated/path/to/file.rbs" }

      it "generates the corresponding RBS file" do
        subject

        expect(rbs_path).to exist
        expect(rbs_path.read).to include "class File"
      end
    end

    context "when file change is received" do
      before do
        rb_path.parent.mkpath
        rb_path.write("class File; end")
      end

      let(:changes) do
        [
          { uri: "file:///#{workspace_path}/path/to/file.rb",
            type: FileChangeType::CHANGED }
        ]
      end
      let(:rb_path) { workspace_path / "path/to/file.rb" }
      let(:rbs_path) { workspace_path / "sig/generated/path/to/file.rbs" }

      it "generates the corresponding RBS file" do
        subject

        expect(rbs_path).to exist
        expect(rbs_path.read).to include "class File"
      end
    end

    context "when file deleted is received" do
      let(:changes) do
        [
          { uri: "file:///#{workspace_path}/path/to/file.rb",
            type: FileChangeType::DELETED }
        ]
      end
      let(:rbs_path) { workspace_path / "sig/generated/path/to/file.rbs" }

      context "when the RBS file corresponding to the deleted Ruby file exists" do
        before do
          rbs_path.parent.mkpath
          rbs_path.write("") # Create a dummy RBS file
        end

        it "deletes the corresponding RBS file" do
          subject

          expect(rbs_path).not_to exist
        end
      end

      context "when the RBS file corresponding to the deleted Ruby file does not exist" do
        it "does not raise an error" do
          subject

          expect(rbs_path).not_to exist
        end
      end
    end
  end
end
