#!/usr/bin/env ruby

require 'fileutils'
require 'json'
require 'logger'
require 'pathname'
require 'optparse'
require 'ruby-progressbar'
require 'concurrent-ruby'

class ProjectAnalyzer
  def initialize(options)
    @input_dir = File.expand_path(options[:input_dir] || '.')
    @output_dir = options[:output_dir] || File.join(@input_dir, 'output')
    @output_file = options[:output_file] || "project_overview_#{Time.now.strftime('%Y%m%d_%H%M%S_%L')}"
    @extensions = options[:extensions] || ['.rb', '.json']
    @logger = options[:logger]
  end

  def run
    validate_input_directory
    files = get_relevant_files
    total_files = files.values.flatten.size

    if total_files.zero?
      @logger.error("No files found with extensions: #{@extensions.join(', ')}")
      return
    end

    write_output(files)
  end

  private

  def validate_input_directory
    unless Dir.exist?(@input_dir)
      @logger.error("Input directory does not exist: #{@input_dir}")
      exit(1)
    end
  end

  def get_relevant_files
    files = Hash.new { |hash, key| hash[key] = [] }
    @logger.info("Scanning directory: #{@input_dir}")

    Dir.glob(File.join(@input_dir, '**', '*')).each do |file|
      next unless File.file?(file)
      ext = File.extname(file)
      if @extensions.include?(ext)
        files[ext] << file
        @logger.debug("Found #{ext} file: #{file}")
      end
    end

    @extensions.each do |ext|
      @logger.info("#{ext} files found: #{files[ext]&.size || 0}")
    end

    files
  end

  def write_output(files)
    FileUtils.mkdir_p(@output_dir)
    output_path = File.join(@output_dir, "#{@output_file}.md")

    total_files = files.values.flatten.size
    progressbar = ProgressBar.create(total: total_files, format: "%a %e %P% Processed: %c from %C")

    File.open(output_path, 'w', encoding: 'UTF-8') do |out_file|
      files.each do |ext, file_list|
        language = ext_language(ext)
        file_list.sort.each do |file|
          relative_path = Pathname.new(file).relative_path_from(Pathname.new(@input_dir)).to_s
          out_file.puts "## #{relative_path}\n\n```#{language}"

          begin
            content = File.read(file, encoding: 'UTF-8')
            content = format_content(ext, content)
            out_file.puts content
            @logger.info("Processed #{relative_path}")
          rescue => e
            error_message = "Error reading #{relative_path}: #{e.message}"
            @logger.error(error_message)
            @logger.debug(e.backtrace.join("\n"))
            out_file.puts error_message
          end

          out_file.puts "```\n\n"
          progressbar.increment
        end
      end
    end

    @logger.info("Output written to #{output_path}")
    @logger.info("Total files processed: #{total_files}")
  end

  def ext_language(ext)
    case ext
    when '.rb' then 'ruby'
    when '.json' then 'json'
    else ext[1..-1] # Remove the dot
    end
  end

  def format_content(ext, content)
    if ext == '.json'
      JSON.pretty_generate(JSON.parse(content))
    else
      content
    end
  rescue JSON::ParserError => e
    @logger.warn("Failed to parse JSON: #{e.message}")
    content
  end
end

# Main execution starts here
options = {
  logger: Logger.new(STDOUT)
}

OptionParser.new do |opts|
  opts.banner = "Usage: project_analyzer.rb [options]"

  opts.on("-i", "--input DIR", "Input directory to scan") do |dir|
    options[:input_dir] = dir
  end

  opts.on("-o", "--output DIR", "Output directory") do |dir|
    options[:output_dir] = dir
  end

  opts.on("-f", "--file FILE", "Output file name (without extension)") do |file|
    options[:output_file] = file
  end

  opts.on("-l", "--log-level LEVEL", "Set log level (DEBUG, INFO, WARN, ERROR)") do |level|
    options[:log_level] = level
  end

  opts.on("-e", "--extensions x,y,z", Array, "File extensions to include (default: .rb,.json)") do |list|
    options[:extensions] = list.map { |ext| ext.start_with?('.') ? ext : ".#{ext}" }
  end

  opts.on("-h", "--help", "Displays Help") do
    puts opts
    exit
  end
end.parse!

# Set logging level
options[:logger].level = case options[:log_level]&.upcase
                         when 'DEBUG' then Logger::DEBUG
                         when 'WARN' then Logger::WARN
                         when 'ERROR' then Logger::ERROR
                         else Logger::INFO
                         end

options[:logger].formatter = proc do |severity, datetime, progname, msg|
  "#{datetime.strftime('%Y-%m-%d %H:%M:%S')} - #{severity} - #{msg}\n"
end

analyzer = ProjectAnalyzer.new(options)
analyzer.run
