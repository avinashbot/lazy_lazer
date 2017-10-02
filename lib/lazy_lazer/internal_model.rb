# frozen_string_literal: true

require 'set'

module LazyLazer
  # A delegator for internal operations.
  class InternalModel
    # Create an internal model with a reference to a public model.
    # @param key_metadata [KeyMetadataStore] a reference to a metadata store
    # @param parent [LazyLazer] a reference to a LazyLazer model
    def initialize(key_metadata, parent)
      @key_metadata = key_metadata
      @parent = parent
      @cache = {}
      @source = {}
      @writethrough = {}
      @fully_loaded = false
    end

    # Converts all unconverted keys and packages them as a hash.
    # @return [Hash] the converted hash
    def to_h(strict: false)
      todo = @key_metadata.keys - @cache.keys
      todo.each do |key|
        strict ? load_key_strict(key) : load_key_lenient(key)
      end
      @cache.dup
    end

    # @return [String] the string representation of the parent
    def inspect
      "#<#{@parent.class.name} (#{@fully_loaded ? 'loaded' : 'unloaded'}): [" + \
        @cache.keys.join(', ') + ']>'
    end

    # Whether the key doesn't need to be lazily loaded.
    # @param key_name [Symbol] the key to check
    # @return [Boolean] whether the key exists locally.
    def exists_locally?(key_name)
      return true if @cache.key?(key_name) || @writethrough.key?(key_name)
      meta = ensure_metadata_exists(key_name)
      @source.key?(meta.source_key)
    end

    # Get the value of a key (fetching it from the cache if possible)
    # @param key_name [Symbol] the name of the key
    # @return [Object] the returned value
    # @raise MissingAttribute if the attribute wasn't found and there isn't a default
    def read_attribute(key_name)
      @cache.fetch(key_name) { load_key_strict(key_name) }
    end

    # Update an attribute.
    # @param key_name [Symbol] the attribute to update
    # @param new_value [Object] the new value
    # @return [Object] the written value
    def write_attribute(key_name, new_value)
      meta = ensure_metadata_exists(key_name)
      @source.delete(meta.source_key)
      @writethrough[key_name] = @cache[key_name] = new_value
    end

    # Delete an attribute
    # @param key_name [Symbol] the name of the key
    # @return [void]
    def delete_attribute(key_name)
      key_name_sym = key_name.to_sym
      meta = ensure_metadata_exists(key_name_sym)
      @cache.delete(key_name)
      @writethrough.delete(key_name)
      @source.delete(meta.source_key)
      nil
    end

    # Mark the model as fully loaded.
    # @return [void]
    def fully_loaded!
      @fully_loaded = true
    end

    # Mark the model as not fully loaded.
    # @return [void]
    def not_fully_loaded!
      @fully_loaded = false
    end

    # @return [Boolean] whether the object is done with lazy loading
    def fully_loaded?
      @fully_loaded
    end

    # Verify that all the keys marked as required are present.
    # @api private
    # @raise RequiredAttribute if a required attribute is missing
    # @return [void]
    def verify_required!
      @key_metadata.required_properties.each do |key_name|
        next if @source.key?(@key_metadata.get(key_name).source_key)
        raise RequiredAttribute, "#{@parent} requires `#{key_name}`"
      end
    end

    # @api private
    # @return [Array] the identity properties
    def required_properties
      @key_metadata.required_properties
    end

    # Merge a hash into the model.
    # @api private
    # @param attributes [Hash<Symbol, Object>] the attributes to merge
    def merge!(attributes)
      @cache.clear
      @source.merge!(attributes)
    end

    private

    # Load the key and apply transformations to it, skipping the cache.
    # @param key_name [Symbol] the key name
    # @return [Object] the returned value
    # @raise MissingAttribute if the attribute wasn't found and there isn't a default
    def load_key_strict(key_name)
      meta = ensure_metadata_exists(key_name)
      reload_if_missing(key_name, meta.source_key)
      if !exists_locally?(key_name) && !meta.default_provided?
        raise MissingAttribute, "`#{meta.source_key} is missing for #{@parent}`"
      end
      parse_key(meta, key_name)
    end

    # Load the key and apply transformations to it, skipping the cache.
    # @param key_name [Symbol] the key name
    # @return [Object] the returned value
    def load_key_lenient(key_name)
      meta = ensure_metadata_exists(key_name)
      reload_if_missing(key_name, meta.source_key)
      parse_key(meta, key_name)
    end

    def reload_if_missing(key_name, source_key)
      @parent.reload if !@writethrough.key?(key_name) && !@source.key?(source_key) && !@fully_loaded
    end

    def parse_key(meta, key_name)
      if @source.key?(meta.source_key)
        @cache[key_name] = transform_value(@source[meta.source_key], meta.transform)
      elsif @writethrough.key?(key_name)
        @cache[key_name] = @writethrough[key_name]
      elsif meta.default_provided?
        @cache[key_name] = fetch_default(meta.default)
      end
    end

    # Ensure the metadata is found.
    # @param key_name [Symbol] the property name
    # @return [KeyMetadata] the key metadata, if found
    # @raise MissingAttribute if the key metadata wasn't found
    def ensure_metadata_exists(key_name)
      return @key_metadata.get(key_name) if @key_metadata.contains?(key_name)
      raise MissingAttribute, "`#{key_name}` isn't defined for #{@parent}"
    end

    # Apply a transformation to a value.
    # @param value [Object] a value
    # @param transform [nil, Proc, Symbol] a transform type
    # @return [Object] the transformed value
    def transform_value(value, transform)
      case transform
      when nil
        value
      when Proc
        @parent.instance_exec(value, &transform)
      when Symbol
        value.public_send(transform)
      end
    end

    # Run the default proc and return its value, if applicable.
    # @param default [Proc, Object] a proc to run, or an object to return
    # @return [Object] the processed value
    def fetch_default(default)
      return @parent.instance_exec(&default) if default.is_a?(Proc)
      default
    end
  end
end
