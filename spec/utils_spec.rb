require 'spec_helper'
require_relative '../lib/spooky2tool/utils'
require 'tempfile'
require 'logger'

RSpec.describe Spooky2Tool::Utils do
  describe '.setup_logging' do
    it 'creates a logger with the specified level' do
      logger = Spooky2Tool::Utils.setup_logging(level: Logger::DEBUG)
      expect(logger).to be_a(Logger)
      expect(logger.level).to eq(Logger::DEBUG)
    end

    it 'creates a log file' do
      log_file = 'test_log.log'
      logger = Spooky2Tool::Utils.setup_logging(log_file: log_file)
      expect(File.exist?(log_file)).to be true
      File.delete(log_file)
    end
  end

  describe '.create_timestamp' do
    it 'returns a string in the correct format' do
      timestamp = Spooky2Tool::Utils.create_timestamp
      expect(timestamp).to match(/\d{8}_\d{6}/)
    end
  end

  describe '.save_metadata' do
    it 'saves metadata to a JSON file' do
      metadata = { 'key' => 'value' }
      output_dir = Dir.mktmpdir
      filename = 'test_metadata.json'

      Spooky2Tool::Utils.save_metadata(metadata, output_dir, filename: filename)

      full_path = File.join(output_dir, filename)
      expect(File.exist?(full_path)).to be true
      content = JSON.parse(File.read(full_path))
      expect(content).to eq(metadata)

      FileUtils.remove_entry(output_dir)
    end
  end

  describe '.ensure_directory_exists' do
    it 'creates a directory if it does not exist' do
      dir = File.join(Dir.tmpdir, 'test_dir')
      Spooky2Tool::Utils.ensure_directory_exists(dir)
      expect(Dir.exist?(dir)).to be true
      Dir.rmdir(dir)
    end

    it 'does not raise an error if the directory already exists' do
      dir = Dir.mktmpdir
      expect {
        Spooky2Tool::Utils.ensure_directory_exists(dir)
      }.not_to raise_error
      FileUtils.remove_entry(dir)
    end
  end

  describe '.get_file_size' do
    it 'returns the correct file size' do
      file = Tempfile.new('test')
      file.write('test content')
      file.close

      size = Spooky2Tool::Utils.get_file_size(file.path)
      expect(size).to eq(12)  # 'test content' is 12 bytes

      file.unlink
    end

    it 'returns 0 for non-existent files' do
      size = Spooky2Tool::Utils.get_file_size('non_existent_file.txt')
      expect(size).to eq(0)
    end
  end

  describe '.is_valid_frequency?' do
    it 'returns true for frequencies within the valid range' do
      expect(Spooky2Tool::Utils.is_valid_frequency?(100)).to be true
      expect(Spooky2Tool::Utils.is_valid_frequency?(0.01)).to be true
      expect(Spooky2Tool::Utils.is_valid_frequency?(25000000)).to be true
    end

    it 'returns false for frequencies outside the valid range' do
      expect(Spooky2Tool::Utils.is_valid_frequency?(0)).to be false
      expect(Spooky2Tool::Utils.is_valid_frequency?(25000001)).to be false
    end
  end
end