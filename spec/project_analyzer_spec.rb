# spec/project_analyzer_spec.rb
require 'rspec'
require_relative '../project_analyzer'

RSpec.describe ProjectAnalyzer do
  let(:options) { { input_dir: 'spec/fixtures', logger: Logger.new('/dev/null') } }
  let(:analyzer) { ProjectAnalyzer.new(options) }

  describe '#get_relevant_files' do
    it 'finds the correct number of files' do
      files = analyzer.send(:get_relevant_files)
      expect(files['.rb'].size).to eq(2)  # Adjust based on your test fixtures
      expect(files['.json'].size).to eq(1)
    end
  end
end
# frozen_string_literal: true

