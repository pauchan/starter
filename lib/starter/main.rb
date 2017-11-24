require "rpi_gpio"
require "starter/service"

module Starter
  class Main
    LIGHTS = {
      red: 17,
      yellow: 27,
      green: 22
    }

    def run
      initialize_pins

      while true do
        fetch_and_update
        sleep 300
      end

    rescue Interrupt, Exception => e
      turn_off_all_lights
      reset_pins
      raise
    end

    private

      def initialize_pins
        RPi::GPIO.set_numbering :bcm
        LIGHTS.values.each do |pin|
          RPi::GPIO.setup pin, as: :output
        end
      end

      def fetch_and_update
        result = Service.new.run
        update_status result[:status]
        logger.info "Value: #{result[:value]}"
      end

      def update_status(status)
        turn_off_all_lights
        pin = LIGHTS[status]
        if pin
          RPi::GPIO.set_high pin
        end
      end

      def turn_off_all_lights
        LIGHTS.values.each do |pin|
          RPi::GPIO.set_low pin
        end
      end

      def reset_pins
        RPi::GPIO.reset
      end

      def logger
        @_logger ||= build_logger
      end

      def build_logger
        logger = Logger.new(STDOUT)
        logger.formatter = ->(_, datetime, _, msg) { "#{datetime} - #{msg}\n" }
        logger
      end
  end
end
