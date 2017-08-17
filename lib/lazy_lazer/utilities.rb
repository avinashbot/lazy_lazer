# frozen_string_literal: true

module LazyLazer
  # Utility methods.
  module Utilities
    def self.lookup_default(source, key, default)
      return source[key] if source.key?(key)
      return default.call if default.is_a?(Proc)
      default
    end

    # Transforms a value using a "transformer" supplied using :with.
    # @param [Object] value the value to transform
    # @param [nil, Symbol, Proc] transformer the transformation method
    # @param [Object] context the context to run the proc in
    # @return [Object] the result of applying the transformation to the value
    def self.transform_value(value, transformer)
      case transformer
      when nil
        value
      when Symbol
        value.public_send(transformer)
      when Proc
        transformer.call(value)
      end
    end
  end
end
