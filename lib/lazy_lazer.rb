# frozen_string_literal: true

require_relative 'lazy_lazer/version'
require_relative 'lazy_lazer/errors'
require_relative 'lazy_lazer/utilities'

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
    def inherited(klass)
      klass.instance_variable_set(:@_lazer_properties, @_lazer_properties)
      klass.instance_variable_set(:@_lazer_required_properties, @_lazer_required_properties)
    end

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
      define_method(name) { read_attribute(name) }
    end
  end

  # The base model class. This could be included directly.
  module InstanceMethods
    # Initializer.
    #
    # @param [Hash] attributes the model attributes
    # @return [void]
    def initialize(attributes = {})
      # Check all required attributes.
      self.class.instance_variable_get(:@_lazer_required_properties).each do |prop|
        raise RequiredAttribute, "#{self} requires `#{prop}`" unless attributes.key?(prop)
      end

      @_lazer_attribute_source = attributes.dup
      @_lazer_attribute_cache = {}
    end

    def to_h(strict = true)
      if strict
        remaining = @_lazer_attribute_source.keys - @_lazer_attribute_cache.keys
        remaining.each do |key|
          @_lazer_attribute_cache[key] = read_attribute(key)
        end
      end
      @_lazer_attribute_cache
    end

    def reload; end

    # @note this differs from the Rails implementation and raises {MissingAttribute} if the
    #   attribute wasn't found.
    def read_attribute(name)
      return @_lazer_attribute_cache[name] if @_lazer_attribute_cache.key?(name)
      reload if self.class.properties.key?(name) && !fully_loaded?
      options = self.class.properties.fetch(name, {})

      if !@_lazer_attribute_source.key?(name) && !options.key?(:default)
        raise MissingAttribute, "#{name} is missing for #{self}"
      end
      uncoerced = Utilities.lookup_default(@_lazer_attribute_source, name, options[:default])
      Utilities.transform_value(uncoerced, options[:with])
    end
    alias [] read_attribute

    def write_attribute(attribute, value)
      @_lazer_attribute_cache[attribute] = value
    end

    def assign_attributes(new_attributes)
      new_attributes.each { |key, value| write_attribute(key, value) }
    end
    alias attributes= assign_attributes

    def fully_loaded?
      @_lazer_fully_loaded ||= false
    end

    private

    def fully_loaded=(state)
      @_lazer_fully_loaded = state
    end
  end
end
