#!/usr/bin/env ruby

# Add the lib directory to the load path
$LOAD_PATH.unshift File.expand_path('../lib', __dir__)

require 'spooky2tool'
require 'clipboard'
require 'json'
require 'fileutils'

def read_clipboard_content
  content = Clipboard.paste
  content.encode!('UTF-8', 'UTF-8', invalid: :replace, undef: :replace, replace: '')

  if content.encoding == Encoding::UTF_16LE || content.start_with?("\xFF\xFE")
    content = content.encode('UTF-8', 'UTF-16LE')
  end

  content
end

def main
  # Check if we're being run by OCRA
  if defined?(Ocra)
    puts "OCRA is compiling the script. Skipping main functionality."
    return
  end

  logger = nil
  begin
    timestamp = Spooky2Tool::Utils.create_timestamp
    log_file = File.join(Dir.pwd, "spooky2tool_#{timestamp}.log")
    logger = Spooky2Tool::Utils.setup_logging(log_file: log_file, level: Logger::DEBUG)

    puts "Starting Spooky2Tool F100 to Spooky2 Preset Converter"
    puts "Current directory: #{Dir.pwd}"
    logger.info("Starting Spooky2Tool F100 to Spooky2 Preset Converter")
    logger.info("Current directory: #{Dir.pwd}")

    clipboard_content = read_clipboard_content
    puts "Clipboard content read (#{clipboard_content.length} characters)"
    logger.info("Clipboard content read (#{clipboard_content.length} characters)")
    logger.debug("Clipboard content:\n#{clipboard_content}")

    if clipboard_content.empty?
      error_msg = "Clipboard is empty or content couldn't be read. Please copy an F100 script to the clipboard."
      puts "Error: #{error_msg}"
      logger.error(error_msg)
      return
    end

    puts "Validating input..."
    logger.info("Validating input...")
    begin
      Spooky2Tool::Validator.validate_input(clipboard_content, logger)
    rescue Spooky2Tool::Validator::ValidationError => e
      error_msg = "Input validation failed: #{e.message}"
      puts "Error: The clipboard content is not a valid F100 script. #{e.message}"
      logger.error(error_msg)
      logger.error("Invalid clipboard content:\n#{clipboard_content}")
      return
    end

    puts "Input validation successful. Parsing F100 script..."
    logger.info("Input validation successful. Parsing F100 script...")
    parser = Spooky2Tool::Parser.new(logger)
    parsed_data = parser.parse(clipboard_content)
    logger.debug("Parsed data: #{parsed_data.inspect}")

    if parsed_data[:frequency_objects].empty?
      warn_msg = "No frequency objects were parsed from the input."
      puts "Warning: #{warn_msg}"
      logger.warn(warn_msg)
    end

    header_file = File.expand_path('../config/spooky2_preset_header.txt', __dir__)
    puts "Looking for header file: #{header_file}"
    logger.info("Looking for header file: #{header_file}")
    unless File.exist?(header_file)
      error_msg = "Header file not found: #{header_file}"
      puts "Error: Header file not found. Please ensure 'spooky2_preset_header.txt' is in the config directory."
      logger.error(error_msg)
      return
    end

    header_content = File.read(header_file)
    logger.debug("Header content read (#{header_content.length} characters)")

    puts "Generating Spooky2 preset..."
    logger.info("Generating Spooky2 preset...")
    generator = Spooky2Tool::Generator.new(logger)
    preset_content = generator.generate_spooky2_preset(parsed_data, header_content)

    output_file = generator.save_preset(preset_content, parsed_data[:header][:program_name])

    puts "Spooky2 preset generated successfully!"
    puts "Output file: #{output_file}"
    puts "Program name: #{parsed_data[:header][:program_name]}"
    puts "Number of frequency objects: #{parsed_data[:frequency_objects].size}"
    logger.info("Spooky2 preset generated successfully!")
    logger.info("Output file: #{output_file}")
    logger.info("Program name: #{parsed_data[:header][:program_name]}")
    logger.info("Number of frequency objects: #{parsed_data[:frequency_objects].size}")

    file_size = Spooky2Tool::Utils.get_file_size(output_file)
    puts "Output file size: #{file_size} bytes"
    logger.info("Output file size: #{file_size} bytes")

    metadata = {
      timestamp: timestamp,
      program_name: parsed_data[:header][:program_name],
      frequency_objects_count: parsed_data[:frequency_objects].size,
      output_file: output_file,
      file_size: file_size
    }
    Spooky2Tool::Utils.save_metadata(metadata, File.dirname(output_file))

    puts "For detailed logs, check: #{log_file}"

  rescue StandardError => e
    error_message = "An error occurred: #{e.message}"
    puts error_message
    puts e.backtrace.join("\n")
    if logger
      logger.error(error_message)
      logger.error(e.backtrace.join("\n"))
    end
    puts "An error occurred while processing the F100 script. Please check the logs for more information."
  ensure
    puts "Press Enter to exit."
    gets  # Wait for user input before closing
  end
end

main if __FILE__ == $PROGRAM_NAME