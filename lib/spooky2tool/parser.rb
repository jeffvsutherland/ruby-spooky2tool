# lib/spooky2tool/parser.rb

module Spooky2Tool
  class Parser
    attr_reader :logger

    def initialize(logger = Logger.new(STDOUT))
      @logger = logger
    end

    def parse(content)
      lines = content.split("\n")
      @logger.debug("Parsing #{lines.size} lines")
      result = {
        header: parse_header(lines),
        frequency_objects: parse_frequency_objects(lines)
      }
      @logger.debug("Parsed result: #{result.inspect}")
      result
    end

    private

    def parse_header(lines)
      header = {
        program_name: nil,
        dates: [],
        copyright: nil,
        keywords: [],
        settings: {}
      }

      lines.each do |line|
        case line
        when /^#(.+)$/
          if header[:program_name].nil?
            header[:program_name] = $1.strip
            header[:dates] = $1.scan(/\d{8}/)
          elsif line =~ /^#copyright/i
            header[:copyright] = line.sub(/^#/, '').strip
          else
            header[:keywords] << line.sub(/^#/, '').strip
          end
        when /^(repeat|dwell|program)\s+(.+)$/i
          header[:settings][$1.downcase] = $2
        when /^$/
          next
        else
          break
        end
      end

      @logger.debug("Parsed header: #{header.inspect}")
      header
    end

    def parse_frequency_objects(lines)
      objects = []
      current_object = nil

      lines.each do |line|
        case line
        when /^#(\S+.*?)\s+(\d{8}(?:\s+\d{8})*)$/
          objects << current_object if current_object && !current_object[:fuzz_frequency_pairs].empty?
          current_object = {
            name: $1,
            dates: $2.split,
            fuzz_frequency_pairs: []
          }
        when /^fuzz\s+(.+)$/
          if current_object
            current_object[:fuzz_frequency_pairs] << {
              fuzz: parse_fuzz($1),
              frequencies: [],
              dwell: 60  # Default dwell time
            }
          else
            @logger.warn("Found fuzz command outside of a frequency object: #{line}")
          end
        when /^dwell\s+(\d+)$/
          if current_object && !current_object[:fuzz_frequency_pairs].empty?
            current_object[:fuzz_frequency_pairs].last[:dwell] = $1.to_i
          else
            @logger.warn("Found dwell command in unexpected location: #{line}")
          end
        when /^\s*[\d.]+/
          if current_object && !current_object[:fuzz_frequency_pairs].empty?
            current_object[:fuzz_frequency_pairs].last[:frequencies] += line.split.map(&:to_f)
          else
            @logger.warn("Found frequencies outside of a fuzz-frequency pair: #{line}")
          end
        end
      end

      objects << current_object if current_object && !current_object[:fuzz_frequency_pairs].empty?
      @logger.debug("Parsed #{objects.size} frequency objects")
      objects
    end

    def parse_fuzz(fuzz_string)
      fuzz_string.split.map { |f| f.sub('%', '').to_f / 100 }
    end
  end
end