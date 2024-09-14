# lib/spooky2tool/validator.rb

module Spooky2Tool
  class Validator
    class ValidationError < StandardError; end

    def self.validate_input(content, logger)
      logger.info("Starting validation of input")
      raise ValidationError, "Input is empty" if content.strip.empty?
      validate_structure(content, logger)
      validate_header(content, logger)
      validate_frequency_blocks(content, logger)
      logger.info("Input validation completed successfully")
    end

    def self.validate_structure(content, logger)
      logger.info("Validating structure")
      lines = content.split("\n")
      raise ValidationError, "No header found" unless lines.any? { |line| line.start_with?('#') }
      raise ValidationError, "No frequency data found" unless lines.any? { |line| line.match?(/^\d/) }
    end

    def self.validate_header(content, logger)
      logger.info("Validating header")
      first_line = content.split("\n").first
      unless first_line.match?(/^#.+\s\d{8}$/)
        raise ValidationError, "Invalid header format. Expected: #Program Name YYYYMMDD"
      end
    end

    def self.validate_frequency_blocks(content, logger)
      logger.info("Validating frequency blocks")
      lines = content.split("\n")
      fuzz_lines = lines.select { |line| line.start_with?('fuzz') }
      raise ValidationError, "No fuzz commands found" if fuzz_lines.empty?

      fuzz_lines.each do |fuzz_line|
        unless fuzz_line.match?(/^fuzz\s+((\d+(\.\d+)?%?)|(\.\d+%?))\s+((\d+(\.\d+)?%?)|(\.\d+%?))$/)
          raise ValidationError, "Invalid fuzz command: #{fuzz_line}"
        end
      end

      freq_lines = lines.select { |line| line.match?(/^\d/) }
      freq_lines.each do |freq_line|
        frequencies = freq_line.split.map(&:to_f)
        frequencies.each do |freq|
          unless freq > 0 && freq < 60_000_000  # 60 MHz
            raise ValidationError, "Invalid frequency: #{freq}. Must be greater than 0 and less than 60 MHz."
          end
        end
      end
    end
  end
end