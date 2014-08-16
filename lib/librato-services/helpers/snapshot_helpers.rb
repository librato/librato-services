require 'tilt'

module Librato
  module Services
    module Helpers
      module SnapshotHelpers
        DEFAULT_SNAPSHOT_WIDTH  = 600
        DEFAULT_SNAPSHOT_HEIGHT = 416

        def self.sample_snapshot_payload
          {
            :snapshot => {
              :entity_name => "App API Requests",
              :entity_url => "https://metrics.librato.com/instruments/1234?duration=3600",
              :image_url => "http://snapshots.librato.com/instruments/12345abcd.png"
            }
          }.with_indifferent_access
        end
      end
    end
  end
end
