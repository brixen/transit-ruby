# Copyright 2014 Cognitect. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS-IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

module Transit
  # Converts a transit value to an instance of a type
  # @api private
  class Decoder
    ESC_ESC  = "#{ESC}#{ESC}"
    ESC_SUB  = "#{ESC}#{SUB}"
    ESC_RES  = "#{ESC}#{RES}"

    IDENTITY = ->(v){v}

    GROUND_TAGS = %w[_ s ? i d b ' array map]

    attr_reader :handlers, :default_handler
    def initialize(options={})
      custom_handlers = options[:handlers] || {}
      custom_handlers.each {|k,v| validate_handler(k,v)}
      @handlers = ReadHandlers::DEFAULT_READ_HANDLERS.merge(custom_handlers)
      @default_handler = options[:default_handler] || ReadHandlers::DEFAULT_READ_HANDLER
    end

    # @api private
    class Tag < String; end

    # Decodes a transit value to a corresponding object
    #
    # @param node a transit value to be decoded
    # @param cache
    # @param as_map_key
    # @return decoded object
    def decode(node, cache=RollingCache.new, as_map_key=false)
      case node
      when String
        if cache.has_key?(node)
          cache.read(node)
        else
          parsed = begin
                     if !node.start_with?(ESC)
                       node
                     elsif node.start_with?(TAG)
                       Tag.new(node[2..-1])
                     elsif handler = @handlers[node[1]]
                       handler.from_rep(node[2..-1])
                     elsif node.start_with?(ESC_ESC, ESC_SUB, ESC_RES)
                       node[1..-1]
                     else
                       @default_handler.from_rep(node[1], node[2..-1])
                     end
                   end
          cache.write(parsed) if cache.cacheable?(node, as_map_key)
          parsed
        end
      else
        node
      end
    end

    def validate_handler(key, handler)
      raise ArgumentError.new(CAN_NOT_OVERRIDE_GROUND_TYPES_MESSAGE) if GROUND_TAGS.include?(key)
    end

    CAN_NOT_OVERRIDE_GROUND_TYPES_MESSAGE = <<-MSG
You can not supply custom read handlers for ground types.
MSG

  end
end
