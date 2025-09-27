# frozen_string_literal: true

require "ruby_lsp/addon"
require_relative "logger"

module RubyLsp
  module Rbs
    module Inline
      class Addon < ::RubyLsp::Addon
        include LanguageServer::Protocol::Constant

        attr_reader :global_state #: GlobalState
        attr_reader :logger #: Logger

        # @rbs global_state: GlobalState
        # @rbs message_queue: Thread::Queue
        def activate(global_state, message_queue) #: void
          @global_state = global_state
          @logger = Logger.new(message_queue)
        end

        def deactivate #: void
        end

        def name #: String
          "ruby-lsp-rbs_rails"
        end

        def version #: String
          VERSION
        end

        # @rbs changes: Array[{ uri: String, type: Integer }]
        def workspace_did_change_watched_files(changes) #: void
          changes.each do |change|
            case change[:type]
            when FileChangeType::CREATED, FileChangeType::CHANGED
              # TODO
            when FileChangeType::DELETED
              delete_signature(change[:uri])
            end
          end
        end

        private

        # @rbs uri: String
        def delete_signature(uri) #: void
          path = uri_to_path(uri)
          return unless path.extname == ".rb"

          rbs_path = signature_root_dir / path.sub_ext(".rbs")
          return unless rbs_path.exist?

          rbs_path.delete
          logger.info("Deleted RBS signature: #{rbs_path}")
        rescue StandardError => e
          logger.info("Failed to delete signature for #{path}: #{e.message}")
        end

        # @rbs @workspace_path: Pathname?

        def workspace_path #: Pathname
          @workspace_path ||= Pathname.new(global_state.workspace_path)
        end

        def signature_root_dir #: Pathname
          workspace_path / "sig/generated"
        end

        # @rbs uri: String
        def uri_to_path(uri) #: Pathname
          path = uri.delete_prefix("file://")
          Pathname.new(path).relative_path_from(workspace_path)
        end
      end
    end
  end
end
