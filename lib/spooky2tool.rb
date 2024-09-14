require 'logger'

module Spooky2Tool
  VERSION = '0.1.0'
end

require_relative 'spooky2tool/utils'
require_relative 'spooky2tool/parser'
require_relative 'spooky2tool/formatter'
require_relative 'spooky2tool/generator'
require_relative 'spooky2tool/validator'  # Add this line