# frozen_string_literal: true

require_relative 'errors'

module LazyLazer
  # Simple PORO for key metadata. Yay value objects!
  class KeyMetadata
    # @return [Symbol] the key to fetch the value from
    attr_reader :source_key

    # @return [Proc, Object] the default value or generator
    attr_reader :default

    # @return [Proc, Symbol, nil] the method or proc that transforms the return value
    attr_reader :transform

    # Load attributes from a {LazyLazer::ClassMethods#property} method signature.
    # @see LazyLazer::ClassMethods#property
    def self.from_options(key_name, *boolean_options, **options)
      boolean_options.each_with_object(options) { |sym, hsh| hsh[sym] = true }
      KeyMetadata.new(
        source_key: options[:from] || key_name,
        required: !!options[:required],
        runtime_required: !options.key?(:default) && !options[:nil],
        transform: options[:with],
        default: options[:default]
      )
    end

    # Create a new KeyMetadata value object with all the properties.
    # @param source_key [Symbol] the key to fetch the value from
    # @param required [Boolean] whether the key must exist when creating the model
    # @param runtime_required [Boolean] whether the key must exist when loaded
    # @param default [Proc, Object] the default value or generator
    # @param transform [Proc, Symbol, nil] the method or proc that transforms the return value
    def initialize(source_key:, required:, runtime_required:, default:, transform:)
      @source_key = source_key
      @required = required
      @runtime_required = runtime_required
      @default = default
      @transform = transform
      freeze
    end

    # @return [Boolean] whether the key must exist when creating the model
    def required?
      @required
    end

    # @return [Boolean] whether the key must exist when loaded
    def runtime_required?
      @runtime_required
    end
  end
end
