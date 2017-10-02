# frozen_string_literal: true

require_relative 'lazy_lazer/errors'
require_relative 'lazy_lazer/internal_model'
require_relative 'lazy_lazer/key_metadata_store'
require_relative 'lazy_lazer/key_metadata'
require_relative 'lazy_lazer/version'

# LazyLazer.
# Include this module into your class to infuse it with lazer powers.
#
# @see LazyLazer::ClassMethods your model's class methods
# @see LazyLazer::InstanceMethods your model's instance methods
module LazyLazer
  # Hook into `include LazyLazer`.
  # @param base [Module] the object to include the methods in
  # @return [void]
  def self.included(base)
    base.extend(ClassMethods)
    base.include(InstanceMethods)
    base.instance_variable_set(:@_lazer_metadata, KeyMetadataStore.new)
  end

  # The methods to extend the class with.
  module ClassMethods
    # Copies parent properties into subclasses.
    # @param klass [Class] the subclass
    # @return [void]
    def inherited(klass)
      klass.instance_variable_set(:@_lazer_metadata, @_lazer_metadata.dup)
    end

    # Define a property.
    # @param name [Symbol] the name of the property method
    # @param bool_options [Array<Symbol>] options that are set to true
    # @param options [Hash] the options to create the property with
    # @option options [Boolean] :required (false) whether existence of this property should be
    #   checked on model creation
    # @option options [Boolean] :nil (false) shortcut for default: nil
    # @option options [Object, Proc] :default the default value to return if not provided
    # @option options [Symbol] :from (name) the key in the source object to get the property from
    # @option options [Proc, Symbol, nil] :with an optional transformation to apply to the value
    # @return [Symbol] the name of the created property
    #
    # @example
    #   class MyModel
    #     include LazyLazer
    #
    #     property :id, :required
    #     property :timestamp, with: ->(i) { Time.at(i) }
    #     property :created_at, default: ->() { Time.now }
    #     property :camel_case, from: :camelCase
    #   end
    def property(name, *bool_options, **options)
      sym_name = name.to_sym
      @_lazer_metadata.add(sym_name, KeyMetadata.new(sym_name, *bool_options, **options))
      define_method(sym_name) { read_attribute(sym_name) }
    end
  end

  # The methods to extend the instance with.
  module InstanceMethods
    # Create a new instance of the class from a set of source attributes.
    # @param attributes [Hash] the model attributes
    # @return [void]
    # @raise RequiredAttribute if an attribute marked as required wasn't found
    def initialize(attributes = {})
      @_lazer_model = InternalModel.new(self.class.instance_variable_get(:@_lazer_metadata), self)
      @_lazer_model.merge!(attributes)
      @_lazer_model.verify_required!
    end

    # Equality check, performed using required keys.
    # @param other [Object] the other object
    # @return [Boolean]
    def ==(other)
      return false if self.class != other.class
      return super if @_lazer_model.required_properties.empty?
      @_lazer_model.required_properties.each do |key_name|
        return false if self[key_name] != other[key_name]
      end
      true
    end

    # Converts all the attributes that haven't been converted yet and returns the final hash.
    # @return [Hash] a hash representation of the model
    def to_h
      @_lazer_model.parent_to_h
    end

    # @return [String] a human-friendly view of the model
    def inspect
      @_lazer_model.parent_inspect
    end

    # Reload the object. Calls {#lazer_reload}, then merges the results into the internal store.
    # Also clears out the internal cache.
    # @return [self] the updated object
    def reload
      new_attributes = lazer_reload.to_h
      @_lazer_model.merge!(new_attributes)
      self
    end

    # Return the value of the attribute.
    # @param key_name [Symbol] the attribute name
    # @return [Object] the returned value
    # @raise MissingAttribute if the key was not found
    def read_attribute(key_name)
      @_lazer_model.read_attribute(key_name.to_sym)
    end

    # Return the value of the attribute, returning nil if not found.
    # @param key_name [Symbol] the attribute name
    # @return [Object] the returned value
    def [](key_name)
      read_attribute(key_name)
    rescue MissingAttribute
      nil
    end

    # Update an attribute.
    # @param key_name [Symbol] the attribute to update
    # @param new_value [Object] the new value
    # @return [Object] the written value
    def write_attribute(key_name, new_value)
      @_lazer_model.write_attribute(key_name, new_value)
    end

    # Update multiple attributes at once.
    # @param new_attributes [Hash<Symbol, Object>] the new attributes
    # @return [self] the updated object
    def assign_attributes(new_attributes)
      new_attributes.each { |key, value| write_attribute(key, value) }
      self
    end
    alias attributes= assign_attributes

    # @return [Boolean] whether the object is done with lazy loading
    def fully_loaded?
      @_lazer_model.fully_loaded
    end

    private

    # @abstract Provides reloading behaviour for lazy loading.
    # @return [Hash] the result of reloading the hash
    def lazer_reload
      fully_loaded!
      {}
    end

    # Whether the key doesn't need to be lazily loaded.
    # @param key_name [Symbol] the key to check
    # @return [Boolean] whether the key exists locally.
    def exists_locally?(key_name)
      @_lazer_model.exists_locally?(key_name)
    end

    # Mark a key as tainted, forcing a reload on the next lookup.
    # @param key_name [Symbol] the key to invalidate
    # @return [void]
    def invalidate(key_name)
      @_lazer_model.invalidate(key_name)
    end

    # Mark the model as fully loaded.
    # @return [void]
    def fully_loaded!
      @_lazer_model.fully_loaded = true
    end

    # Mark the model as not fully loaded.
    # @return [void]
    def not_fully_loaded!
      @_lazer_model.fully_loaded = false
    end
  end
end
