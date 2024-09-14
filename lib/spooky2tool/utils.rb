# lib/spooky2tool/utils.rb

require 'logger'
require 'fileutils'
require 'json'

module Spooky2Tool
  module Utils
    def self.setup_logging(log_file: 'spooky2tool.log', level: Logger::INFO)
      FileUtils.mkdir_p(File.dirname(log_file))

      file_logger = Logger.new(log_file)
      console_logger = Logger.new(STDOUT)

      [file_logger, console_logger].each do |logger|
        logger.level = level
        logger.formatter = proc do |severity, datetime, progname, msg|
          formatted_datetime = datetime.strftime("%Y-%m-%d %H:%M:%S")
          "[#{formatted_datetime}] #{severity}: #{msg}\n"
        end
      end

      combined_logger = Logger.new(log_file)
      combined_logger.level = level
      combined_logger.formatter = file_logger.formatter

      def combined_logger.add(severity, message = nil, progname = nil)
        super
        puts "#{formatter.call(severity, Time.now, progname, message)}"
      end

      combined_logger
    end

    def self.create_timestamp
      Time.now.strftime("%Y%m%d_%H%M%S")
    end

    def self.save_metadata(metadata, output_dir, filename: 'metadata.json')
      filepath = File.join(output_dir, filename)
      FileUtils.mkdir_p(output_dir) unless Dir.exist?(output_dir)

      File.open(filepath, 'w') do |file|
        file.write(JSON.pretty_generate(metadata))
      end

      puts "Metadata saved to #{filepath}"
    rescue IOError => e
      puts "Error saving metadata to #{filepath}: #{e.message}"
    end

    def self.ensure_directory_exists(directory)
      FileUtils.mkdir_p(directory) unless Dir.exist?(directory)
      puts "Created directory: #{directory}"
    end

    def self.get_file_size(filepath)
      File.size(filepath)
    rescue Errno::ENOENT => e
      puts "Error getting file size for #{filepath}: #{e.message}"
      0
    end

    def self.is_valid_frequency?(freq, min_freq: 0.01, max_freq: 25_000_000)
      freq >= min_freq && freq <= max_freq
    end
  end
end