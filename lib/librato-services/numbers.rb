module Librato
  module Services
    class Numbers
      def self.format_for_threshold(threshold, number, tolerance=2)
        threshold_decimals = number_decimal_places(threshold)
        number_decimals = number_decimal_places(number)

        if !threshold_decimals || !number_decimals
          return number
        end

        if (number_decimals - tolerance) <= threshold_decimals
          return number
        end

        # here we have more decimals in the number than the threshold
        # number:    3.14159
        # threshold: 3.14

        factor = (10**(threshold_decimals+tolerance)).to_f
        (number * factor).truncate / factor
      end

      def self.number_decimal_places(number)
        segments = number.to_s.split('.')
        if segments.length != 2
          return 0
        end
        segments[1].length
      end
    end
  end
end

