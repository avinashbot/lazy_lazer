# frozen_string_literal: true

require_relative 'errors'

module LazyLazer
  # Simple PORO for key metadata. Yay value objects!
  class KeyMetadata
    # @return [Symbol] the key to fetch the value from
    attr_accessor :source_key

    # @return [Boolean] whether the key must exist when creating the model
    attr_writer :required

    # @return [Boolean] whether a default was provided
    attr_writer :default_provided

    # @return [Proc, Object] the default value or generator
    attr_accessor :default

    # @return [Proc, Symbol, nil] the method or proc that transforms the return value
    attr_accessor :transform

    # Load attributes from a {LazyLazer::ClassMethods#property} method signature.
    # @see LazyLazer::ClassMethods#property
    def initialize(key_name, *boolean_options, **options)
      boolean_options.each_with_object(options) { |sym, hsh| hsh[sym] = true }
      self.source_key = options[:from] || key_name
      self.required = !!options[:required]
      self.default_provided = options.key?(:default) || options[:nil]
      self.transform = options[:with]
      self.default = options[:default]
    end

    # @return [Boolean] whether the key must exist when creating the model
    def required?
      @required
    end

    # @return [Boolean] whether no default was provided
    def default_provided?
      @default_provided
    end
  end
end
