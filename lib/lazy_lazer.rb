# frozen_string_literal: true

require_relative 'lazy_lazer/version'
require_relative 'lazy_lazer/errors'

# LazyLazer is a lazy loading model.
module LazyLazer
  # Hook into `include LazyLazer`.
  #
  # @param [Module] base the object to include the methods in
  # @return [void]
  def self.included(base)
    base.extend(ClassMethods)
    base.include(InstanceMethods)
    base.instance_variable_set(:@_lazer_properties, {})
    base.instance_variable_set(:@_lazer_required_properties, [])
  end

  # The methods to extend the class with.
  module ClassMethods
    # @return [Hash<Symbol, Hash>] defined properties and their options
    def properties
      @_lazer_properties
    end

    # Define a property.
    # @param [Symbol] name the name of the property method
    # @param [Hash] options the options to create the property with
    # @option options [Boolean] :required (false) whether existence of this
    #   property should be checked on model creation
    # @option options [Symbol, Array<Symbol>] :from (name) the key(s) to get
    #   the value of the property from
    # @option options [Object, Proc] :default the default value to return if
    #   not provided
    # @option options [Proc, Symbol] :with an optional transformation to apply
    #   to the value of the key
    def property(name, **options)
      sym_name = name.to_sym
      properties[sym_name] = options
      @_lazer_required_properties << sym_name if options[:required]
      sym_name
    end
  end

  # The base model class. This could be included directly.
  module InstanceMethods
    # Initializer.
    #
    # @param [Hash] attributes the model attributes
    # @return [void]
    def initialize(attributes = {})
      self.class.instance_variable_get(:@_lazer_required_properties).each do |prop|
        raise RequiredAttribute, "#{self.class} requires `#{prop}`" unless attributes.key?(prop)
      end
      @_lazer_attributes = {}
      assign_attributes(attributes)
    end

    def to_h
      # TODO: coerce all attributes before return
      @_lazer_attributes
    end

    def fully_loaded?
      @_lazer_fully_loaded ||= false
    end

    def reload; end

    def assign_attributes(new_attributes)
      @_lazer_attributes.merge!(new_attributes)
    end
    alias attributes= assign_attributes

    private

    def fully_loaded=(state)
      @_lazer_fully_loaded = state
    end
  end
end
