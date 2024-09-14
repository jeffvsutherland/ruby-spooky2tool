
require 'spec_helper'
require_relative '../lib/spooky2tool/parser'

RSpec.describe F100Parser do
  let(:parser) { F100Parser.new }

  describe '#parse' do
    context 'with a valid F100 script' do
      let(:valid_script) do
        <<~SCRIPT
          #Sample F100 Program 20240913
          #copyright 2024 Example Corp.
          #keyword1
          #keyword2
          repeat 4
          dwell 60
          #Frequency Set A 20240913 20240914
          fuzz 1% 1
          100
          200
          300
          fuzz 0 0
          400
          500
          600
          #Frequency Set B 20240915
          fuzz 2% 2
          700
          800
          900
        SCRIPT
      end

      it 'correctly parses the header' do
        result = parser.parse(valid_script)
        expect(result[:header][:program_name]).to eq('Sample F100 Program')
        expect(result[:header][:dates]).to eq(['20240913'])
        expect(result[:header][:copyright]).to eq('copyright 2024 Example Corp.')
        expect(result[:header][:keywords]).to contain_exactly('keyword1', 'keyword2')
        expect(result[:header][:settings]).to include('repeat' => '4', 'dwell' => '60')
      end

      it 'correctly parses frequency objects' do
        result = parser.parse(valid_script)
        expect(result[:frequency_objects].size).to eq(2)

        set_a = result[:frequency_objects][0]
        expect(set_a[:name]).to eq('Frequency Set A')
        expect(set_a[:dates]).to eq(['20240913', '20240914'])
        expect(set_a[:fuzz_frequency_pairs].size).to eq(2)
        expect(set_a[:fuzz_frequency_pairs][0][:fuzz]).to eq([0.01, 1])
        expect(set_a[:fuzz_frequency_pairs][0][:frequencies]).to eq([100, 200, 300])
        expect(set_a[:fuzz_frequency_pairs][1][:fuzz]).to eq([0, 0])
        expect(set_a[:fuzz_frequency_pairs][1][:frequencies]).to eq([400, 500, 600])

        set_b = result[:frequency_objects][1]
        expect(set_b[:name]).to eq('Frequency Set B')
        expect(set_b[:dates]).to eq(['20240915'])
        expect(set_b[:fuzz_frequency_pairs].size).to eq(1)
        expect(set_b[:fuzz_frequency_pairs][0][:fuzz]).to eq([0.02, 2])
        expect(set_b[:fuzz_frequency_pairs][0][:frequencies]).to eq([700, 800, 900])
      end
    end

    context 'with an empty script' do
      it 'returns an empty result' do
        result = parser.parse('')
        expect(result[:header]).to eq({program_name: nil, dates: [], copyright: nil, keywords: [], settings: {}})
        expect(result[:frequency_objects]).to be_empty
      end
    end

    context 'with a script containing only header information' do
      let(:header_only_script) do
        <<~SCRIPT
          #Header Only Program 20240913
          #copyright 2024 Example Corp.
          #keyword
          repeat 2
        SCRIPT
      end

      it 'correctly parses the header and returns no frequency objects' do
        result = parser.parse(header_only_script)
        expect(result[:header][:program_name]).to eq('Header Only Program')
        expect(result[:header][:dates]).to eq(['20240913'])
        expect(result[:header][:copyright]).to eq('copyright 2024 Example Corp.')
        expect(result[:header][:keywords]).to contain_exactly('keyword')
        expect(result[:header][:settings]).to include('repeat' => '2')
        expect(result[:frequency_objects]).to be_empty
      end
    end

    context 'with a script containing invalid data' do
      let(:invalid_script) do
        <<~SCRIPT
          Invalid content
          100 200 300
          #Not a proper header
        SCRIPT
      end

      it 'handles the invalid data gracefully' do
        result = parser.parse(invalid_script)
        expect(result[:header]).to eq({program_name: nil, dates: [], copyright: nil, keywords: [], settings: {}})
        expect(result[:frequency_objects]).to be_empty
      end
    end

    context 'with various fuzz commands' do
      let(:fuzz_script) do
        <<~SCRIPT
          #Fuzz Test Program 20240913
          #Fuzz Set A 20240913
          fuzz 0 0
          100
          200
          fuzz 1% 1
          300
          400
          fuzz 2.5% 3
          500
          600
        SCRIPT
      end

      it 'correctly parses different fuzz commands' do
        result = parser.parse(fuzz_script)
        fuzz_pairs = result[:frequency_objects][0][:fuzz_frequency_pairs]

        expect(fuzz_pairs[0][:fuzz]).to eq([0, 0])
        expect(fuzz_pairs[1][:fuzz]).to eq([0.01, 1])
        expect(fuzz_pairs[2][:fuzz]).to eq([0.025, 3])
      end
    end
  end
end# frozen_string_literal: true

