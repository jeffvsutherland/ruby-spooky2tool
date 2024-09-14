require 'spec_helper'
require_relative '../lib/spooky2tool/formatter'

RSpec.describe Spooky2Tool::Formatter do
  let(:formatter) { Spooky2Tool::Formatter.new }

  describe '#format_frequencies' do
    it 'formats single frequencies correctly' do
      frequencies = [100, 200, 300]
      fuzz = [0, 0]
      dwell_time = 60

      result = formatter.format_frequencies(frequencies, fuzz, dwell_time)

      expect(result).to eq(['100.00000000=60', '200.00000000=60', '300.00000000=60'])
    end

    it 'applies fuzz correctly' do
      frequencies = [100, 200, 300]
      fuzz = [0.01, 0.02]  # 1% lower, 2% upper
      dwell_time = 60

      result = formatter.format_frequencies(frequencies, fuzz, dwell_time)

      expect(result).to eq([
                             '99.00000000-102.00000000=60',
                             '198.00000000-204.00000000=60',
                             '297.00000000-306.00000000=60'
                           ])
    end

    it 'uses the provided dwell time' do
      frequencies = [100]
      fuzz = [0, 0]
      dwell_time = 30

      result = formatter.format_frequencies(frequencies, fuzz, dwell_time)

      expect(result).to eq(['100.00000000=30'])
    end
  end

  describe '#apply_frequency_limits' do
    it 'applies minimum frequency limit' do
      formatted_frequencies = ['0.00500000=60', '10.00000000=60']
      result = formatter.apply_frequency_limits(formatted_frequencies, min_freq: 0.01)

      expect(result).to eq(['0.01000000=60', '10.00000000=60'])
    end

    it 'applies maximum frequency limit' do
      formatted_frequencies = ['10000000.00000000=60', '30000000.00000000=60']
      result = formatter.apply_frequency_limits(formatted_frequencies, max_freq: 25000000)

      expect(result).to eq(['10000000.00000000=60', '25000000.00000000=60'])
    end

    it 'handles frequency ranges correctly' do
      formatted_frequencies = ['9.00000000-11.00000000=60', '24000000.00000000-26000000.00000000=60']
      result = formatter.apply_frequency_limits(formatted_frequencies, min_freq: 10, max_freq: 25000000)

      expect(result).to eq(['10.00000000-11.00000000=60', '24000000.00000000-25000000.00000000=60'])
    end
  end

  describe '#group_frequencies' do
    it 'groups frequencies into sets of specified size' do
      formatted_frequencies = (1..1500).map { |i| "#{i}.00000000=60" }
      result = formatter.group_frequencies(formatted_frequencies, max_group_size: 1000)

      expect(result.size).to eq(2)
      expect(result[0].size).to eq(1000)
      expect(result[1].size).to eq(500)
    end
  end

  describe '#format_section' do
    it 'formats a complete section' do
      section = {
        name: 'Test Section',
        frequencies: [100, 200, 300],
        fuzz: [0.01, 0.02],
        dwell_time: 60
      }

      section_name, grouped_freqs = formatter.format_section(section)

      expect(section_name).to eq('Test Section')
      expect(grouped_freqs).to be_an(Array)
      expect(grouped_freqs.first).to include('99.00000000-102.00000000=60')
    end
  end
end