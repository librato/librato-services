
$:.unshift File.join(File.dirname(__FILE__), 'librato-services')

require 'authentication'
require 'app'
require 'service'

module Librato
  module Services
    def self.version
      File.read(File.join(File.dirname(__FILE__), '../VERSION')).chomp
    end
  end
end
