module Spooky2Tool
  class Formatter
    attr_reader :logger

    def initialize(logger = Logger.new(STDOUT))
      @logger = logger
    end

    def format_frequencies(frequencies, fuzz, dwell_time)
      @logger.info("Formatting #{frequencies.size} frequencies with fuzz and dwell time")

      formatted_frequencies = frequencies.map do |freq|
        format_frequency(freq, fuzz, dwell_time)
      end

      @logger.info("Formatted #{formatted_frequencies.size} frequency ranges")
      formatted_frequencies
    end

    def apply_frequency_limits(formatted_frequencies, min_freq: 0.01, max_freq: 25_000_000)
      @logger.info("Applying frequency limits: min=#{min_freq} Hz, max=#{max_freq} Hz")

      limited_frequencies = formatted_frequencies.map do |freq_range|
        apply_limits_to_range(freq_range, min_freq, max_freq)
      end.compact

      @logger.info("Applied limits to #{limited_frequencies.size} frequency ranges")
      limited_frequencies
    end

    def group_frequencies(formatted_frequencies, max_group_size: 1000)
      @logger.info("Grouping frequencies with max group size of #{max_group_size}")

      grouped_frequencies = formatted_frequencies.each_slice(max_group_size).to_a

      @logger.info("Created #{grouped_frequencies.size} groups of frequencies")
      grouped_frequencies
    end

    private

    def format_frequency(freq, fuzz, dwell_time)
      lower_freq = freq * (1 - fuzz[0])
      upper_freq = freq * (1 + fuzz[1])

      if lower_freq == upper_freq
        format("%.5f=#{dwell_time}", lower_freq)
      else
        format("%.5f-%.5f=#{dwell_time}", lower_freq, upper_freq)
      end
    end

    def apply_limits_to_range(freq_range, min_freq, max_freq)
      lower, upper = freq_range.split('-').map(&:to_f)
      dwell_time = freq_range.split('=').last

      lower = [min_freq, [lower, max_freq].min].max
      upper = [min_freq, [upper, max_freq].min].max

      return nil if lower == upper

      format("%.5f-%.5f=#{dwell_time}", lower, upper)
    end
  end
end# frozen_string_literal: true

