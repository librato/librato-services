require 'tilt'

module Librato
  module Services
    module Helpers
      module SnapshotHelpers
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
