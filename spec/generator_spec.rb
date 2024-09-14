require 'spec_helper'
require_relative '../lib/spooky2tool/generator'

RSpec.describe Spooky2Tool::Generator do
  let(:generator) { Spooky2Tool::Generator.new }

  describe '#generate_spooky2_preset' do
    let(:parsed_data) do
      {
        header: {
          program_name: "Test Program",
          dates: ["20240913"],
          copyright: "Copyright 2024",
          keywords: ["test", "spooky2"],
          settings: { "repeat" => "4", "dwell" => "60" }
        },
        frequency_objects: [
          {
            name: "Test Frequency Set",
            dates: ["20240913"],
            fuzz_frequency_pairs: [
              {
                fuzz: [0.01, 1],
                frequencies: [100, 200, 300],
                dwell: 60
              },
              {
                fuzz: [0, 0],
                frequencies: [400, 500, 600],
                dwell: 30
              }
            ]
          }
        ]
      }
    end

    let(:header_content) do
      <<~HEADER
        "[Preset]"
        "PresetName=PLACEHOLDER"
        "Repeat_Each_Frequency=1"
        "Out1_Amplitude=20"
      HEADER
    end

    it 'generates a valid Spooky2 preset' do
      preset = generator.generate_spooky2_preset(parsed_data, header_content)

      expect(preset).to include('"[Preset]"')
      expect(preset).to include('"PresetName=Test Program"')
      expect(preset).to include('"Loaded_Programs=Test Frequency Set 20240913"')
      expect(preset).to include('"Loaded_Frequencies=')
      expect(preset).to include('99.00000000-101.00000000=60')
      expect(preset).to include('400.00000000=30')
      expect(preset).to include('"[/Preset]"')
    end

    it 'includes all frequencies from all frequency objects' do
      preset = generator.generate_spooky2_preset(parsed_data, header_content)

      parsed_data[:frequency_objects].first[:fuzz_frequency_pairs].each do |pair|
        pair[:frequencies].each do |freq|
          expect(preset).to include(freq.to_s)
        end
      end
    end

    it 'applies fuzz correctly' do
      preset = generator.generate_spooky2_preset(parsed_data, header_content)

      expect(preset).to include('99.00000000-101.00000000=60')  # 100 Hz with 1% fuzz
      expect(preset).to include('198.00000000-202.00000000=60') # 200 Hz with 1% fuzz
      expect(preset).to include('297.00000000-303.00000000=60') # 300 Hz with 1% fuzz
    end

    it 'uses correct dwell times' do
      preset = generator.generate_spooky2_preset(parsed_data, header_content)

      expect(preset).to include('=60') # For the first fuzz_frequency_pair
      expect(preset).to include('=30') # For the second fuzz_frequency_pair
    end
  end
end