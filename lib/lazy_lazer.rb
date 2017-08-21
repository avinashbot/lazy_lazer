# frozen_string_literal: true

require_relative 'lazy_lazer/version'
require_relative 'lazy_lazer/errors'

# The LazyLazer root that's included
module LazyLazer
  # Hook into `include LazyLazer`.
  # @param base [Module] the object to include the methods in
  # @return [void]
  def self.included(base)
    base.extend(ClassMethods)
    base.include(InstanceMethods)
    base.instance_variable_set(
      :@lazer_metadata,
      properties: [],
      required: {},
      default: {},
      from: {},
      with: {}
    )
  end

  # Get the source key from an instance
  # @param instance [Object] the instance
  # @param key [Symbol] the property key
  # @return [Symbol] the source key if found or the passed key if not found
  def self.source_key(instance, key)
    instance.class.lazer_metadata[:from].fetch(key, key)
  end

  # The methods to extend the class with.
  module ClassMethods
    # Copies parent properties into subclasses.
    # @param klass [Class] the subclass
    # @return [void]
    def inherited(klass)
      klass.instance_variable_set(:@lazer_metadata, @lazer_metadata)
    end

    # @return [Hash<Symbol, Hash>] the lazer configuration for this model
    def lazer_metadata
      @lazer_metadata
    end

    # Define a property.
    # @param name [Symbol] the name of the property method
    # @param options [Hash] the options to create the property with
    # @option options [Boolean] :required (false) whether existence of this property should be
    #   checked on model creation
    # @option options [Object, Proc] :default the default value to return if not provided
    # @option options [Symbol] :from the key in the source object to get the property from
    # @option options [Proc, Symbol] :with an optional transformation to apply to the value
    # @note both :required and :default can't be provided
    # @return [Symbol] the name of the created property
    def property(name, **options)
      raise 'both :required and :default cannot be given' if options[:required] && options[:default]
      sym_name = name.to_sym
      @lazer_metadata[:properties] << sym_name
      options.each_pair { |option, value| @lazer_metadata[option][sym_name] = value }
      define_method(sym_name) { read_attribute(sym_name) }
    end
  end

  # The methods to extend the instance with.
  module InstanceMethods
    # Create a new instance of the class from a set of source attributes.
    # @param attributes [Hash] the model attributes
    # @return [void]
    def initialize(attributes = {})
      # Check that all required attributes exist.
      self.class.lazer_metadata[:required].keys.each do |property|
        key = LazyLazer.source_key(self, property)
        raise RequiredAttribute, "#{self} requires `#{key}`" unless attributes.key?(key)
      end

      @_lazer_source = attributes.dup
      @_lazer_cache = {}
    end

    # Converts all the attributes that haven't been converted yet and returns the final hash.
    # @param strict [Boolean] whether to fully load all attributes
    # @return [Hash] a hash representation of the model
    def to_h(strict = true)
      if strict
        todo = self.class.lazer_metadata[:properties] - @_lazer_cache.keys
        todo.each { |k| read_attribute(k) }
      end
      @_lazer_cache
    end

    # @abstract Provides reloading behaviour for lazy loading.
    # @return [Hash] the result of reloading the hash
    def lazer_reload
      self.fully_loaded = true
      {}
    end

    # Reload the object. Calls {#lazer_reload}, then merges the results into the internal store.
    # Also clears out the internal cache.
    # @return [self] the updated object
    def reload
      new_attributes = lazer_reload
      @_lazer_source.merge!(new_attributes)
      @_lazer_cache = {}
      self
    end

    # Return the value of the attribute.
    # @param name [Symbol] the attribute name
    # @raise MissingAttribute if the key was not found
    def read_attribute(name)
      # Returns the cached attribute.
      return @_lazer_cache[name] if @_lazer_cache.key?(name)

      # Converts the property into the lookup key.
      source_key = LazyLazer.source_key(self, name)

      # Reloads if a key that should be there isn't.
      reload if !@_lazer_source.key?(source_key) &&
                self.class.lazer_metadata[:required].include?(name) &&
                !fully_loaded?

      # Complains if even after reloading, the key is missing (and there's no default).
      if !@_lazer_source.key?(source_key) && !self.class.lazer_metadata[:default].key?(name)
        raise MissingAttribute, "`#{source_key}` missing for #{self}"
      end

      # Gets the value or gets the default.
      value_or_default = @_lazer_source.fetch(source_key) do
        default = self.class.lazer_metadata[:default][name]
        default.is_a?(Proc) ? instance_exec(&default) : default
      end

      # Transforms the result using :with, if found.
      transformer = self.class.lazer_metadata[:with][name]
      coerced =
        case transformer
        when Symbol
          value_or_default.public_send(transformer)
        when Proc
          instance_exec(value_or_default, &transformer)
        else
          value_or_default
        end

      # Add to cache and return the result.
      @_lazer_cache[name] = coerced
    end

    # Return the value of the attribute, returning nil if not found
    # @param name [Symbol] the attribute name
    def [](name)
      read_attribute(name)
    rescue MissingAttribute
      nil
    end

    # Update an attribute.
    # @param attribute [Symbol] the attribute to update
    # @param value [Object] the new value
    def write_attribute(attribute, value)
      @_lazer_cache[attribute] = value
    end

    # Update multiple attributes at once.
    # @param new_attributes [Hash<Symbol, Object>] the new attributes
    def assign_attributes(new_attributes)
      new_attributes.each { |key, value| write_attribute(key, value) }
    end
    alias attributes= assign_attributes

    # @return [Boolean] whether the object is done with lazy loading
    def fully_loaded?
      @_lazer_fully_loaded ||= false
    end

    private

    # @param state [Boolean] the new state
    def fully_loaded=(state)
      @_lazer_fully_loaded = state
    end
  end
end
