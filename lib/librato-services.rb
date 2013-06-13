
$:.unshift File.join(File.dirname(__FILE__), 'librato-services')
$:.unshift File.expand_path('../..', __FILE__)

require 'authentication'
require 'app'
require 'service'

require 'active_support/core_ext/hash/indifferent_access'

module Librato
  module Services
    def self.version
      File.read(File.join(File.dirname(__FILE__), '../VERSION')).chomp
    end
  end
end
