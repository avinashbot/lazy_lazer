# frozen_string_literal: true

require_relative 'lazy_lazer/errors'
require_relative 'lazy_lazer/internal_model'
require_relative 'lazy_lazer/key_metadata'
require_relative 'lazy_lazer/version'

# The LazyLazer root that's included
module LazyLazer
  # Hook into `include LazyLazer`.
  # @param base [Module] the object to include the methods in
  # @return [void]
  def self.included(base)
    base.extend(ClassMethods)
    base.include(InstanceMethods)
    base.instance_variable_set(:@lazer_metadata, {})
  end

  # The methods to extend the class with.
  module ClassMethods
    # Copies parent properties into subclasses.
    # @param klass [Class] the subclass
    # @return [void]
    def inherited(klass)
      klass.instance_variable_set(:@lazer_metadata, @lazer_metadata.dup)
    end

    # @return [Hash<Symbol, Hash>] the lazer configuration for this model
    def lazer_metadata
      @lazer_metadata
    end

    # Define a property.
    # @param name [Symbol] the name of the property method
    # @option bool_options [Array<Symbol>] options that are set to true
    # @param options [Hash] the options to create the property with
    # @option options [Boolean] :required (false) whether existence of this property should be
    #   checked on model creation
    # @option options [Boolean] :nil (false) shortcut for default: nil
    # @option options [Object, Proc] :default the default value to return if not provided
    # @option options [Symbol] :from (name) the key in the source object to get the property from
    # @option options [Proc, Symbol, nil] :with an optional transformation to apply to the value
    # @return [Symbol] the name of the created property
    def property(name, *bool_options, **options)
      bool_options.each_with_object(options) { |sym, hsh| hsh[sym] = true }
      sym_name = name.to_sym
      @lazer_metadata[sym_name] = KeyMetadata.new(
        source_key: options.fetch(:from, sym_name),
        required: !!options[:required],
        runtime_required: !options.key?(:default) && !options[:nil],
        transform: options[:with],
        default: options[:default]
      )
      define_method(sym_name) { read_attribute(sym_name) }
    end
  end

  # The methods to extend the instance with.
  module InstanceMethods
    # Create a new instance of the class from a set of source attributes.
    # @param attributes [Hash] the model attributes
    # @return [void]
    def initialize(attributes = {})
      @_lazer_model = InternalModel.new(self.class.lazer_metadata, self)
      @_lazer_model.merge!(attributes)
      @_lazer_model.verify_required!
      @_lazer_writethrough = {}
      @_lazer_loaded = false
    end

    # Converts all the attributes that haven't been converted yet and returns the final hash.
    # @return [Hash] a hash representation of the model
    def to_h
      @_lazer_model.to_h
    end

    # @abstract Provides reloading behaviour for lazy loading.
    # @return [Hash] the result of reloading the hash
    def lazer_reload
      fully_loaded!
      {}
    end

    # Reload the object. Calls {#lazer_reload}, then merges the results into the internal store.
    # Also clears out the internal cache.
    # @return [self] the updated object
    def reload
      new_attributes = lazer_reload
      @_lazer_model.merge!(new_attributes)
      self
    end

    # Return the value of the attribute.
    # @param name [Symbol] the attribute name
    # @raise MissingAttribute if the key was not found
    def read_attribute(name)
      key = name.to_sym
      return @_lazer_writethrough[key] if @_lazer_writethrough.key?(key)
      @_lazer_model.fetch(key)
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
      @_lazer_writethrough[attribute] = value
    end

    # Update multiple attributes at once.
    # @param new_attributes [Hash<Symbol, Object>] the new attributes
    def assign_attributes(new_attributes)
      new_attributes.each { |key, value| write_attribute(key, value) }
    end
    alias attributes= assign_attributes

    # @return [Boolean] whether the object is done with lazy loading
    def fully_loaded?
      @_lazer_loaded
    end

    private

    def fully_loaded!
      @_lazer_loaded = true
    end
  end
end
