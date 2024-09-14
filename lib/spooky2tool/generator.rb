# File: lib/spooky2tool/generator.rb

require 'logger'
require 'fileutils'

module Spooky2Tool
  class Generator
    attr_reader :logger

    def initialize(logger = Logger.new(STDOUT))
      @logger = logger
    end

    def generate_spooky2_preset(parsed_data, header)
      logger.info("Generating Spooky2 preset")
      logger.debug("Parsed data: #{parsed_data.inspect}")
      logger.debug("Header: #{header.inspect}")

      preset_content = ['"[Preset]"']
      preset_content += process_header(header, parsed_data[:header][:program_name])

      if parsed_data[:frequency_objects].empty?
        logger.warn("No frequency objects found in parsed data")
      else
        last_freq_obj = parsed_data[:frequency_objects].last
        preset_content << generate_loaded_programs(last_freq_obj)
        preset_content << generate_loaded_frequencies([last_freq_obj])
      end

      preset_content << '"[/Preset]"'

      logger.info("Spooky2 preset generated successfully")
      preset_content.join("\n")
    end

    def save_preset(preset_content, program_name)
      spooky2_dir = 'C:\Spooky2\Preset Collections\User\Biofeedback'
      if Dir.exist?(spooky2_dir)
        output_dir = spooky2_dir
      else
        output_dir = File.join(Dir.pwd, 'output')
        FileUtils.mkdir_p(output_dir)
      end

      sanitized_name = program_name.gsub(/[^\w\s-]/, '').gsub(/\s+/, '_')
      output_file = File.join(output_dir, "#{sanitized_name}.txt")

      File.write(output_file, preset_content)
      logger.info("Preset saved to: #{output_file}")
      output_file
    end

    private

    def process_header(header, program_name)
      header_content = header.strip.split("\n")

      # Remove any existing "[Preset]" lines
      header_content.reject! { |line| line.strip == '"[Preset]"' }

      processed_header = header_content.map do |line|
        if line.start_with?('"PresetName=')
          "\"PresetName=#{program_name}\""
        else
          line
        end
      end

      processed_header
    end

    def generate_loaded_programs(freq_obj)
      "\"Loaded_Programs=#{freq_obj[:name]} #{freq_obj[:dates].join(' ')}\""
    end

    def generate_loaded_frequencies(frequency_objects)
      frequencies = frequency_objects.flat_map do |freq_obj|
        freq_obj[:fuzz_frequency_pairs].flat_map do |pair|
          format_frequencies(pair[:frequencies], pair[:fuzz], pair[:dwell] || 60)
        end
      end

      "\"Loaded_Frequencies=#{frequencies.join(',')}\""
    end

    def format_frequencies(frequencies, fuzz, dwell)
      frequencies.map do |freq|
        if fuzz[0] == 0 && fuzz[1] == 0
          format("%.8f=%d", freq, dwell)
        else
          lower = freq * (1 - fuzz[0])
          upper = freq * (1 + fuzz[1])
          format("%.8f-%.8f=%d", lower, upper, dwell)
        end
      end
    end
  end
end