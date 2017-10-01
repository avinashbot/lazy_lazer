# frozen_string_literal: true

module LazyLazer
  # A delegator for internal operations.
  class InternalModel
    # @return [Boolean] whether the model is fully loaded
    attr_accessor :fully_loaded

    # Create an internal model with a reference to a public model.
    # @param key_metadata [KeyMetadataStore] a reference to a metadata store
    # @param parent [LazyLazer] a reference to a LazyLazer model
    def initialize(key_metadata, parent)
      @key_metadata = key_metadata
      @parent = parent
      @invalidated = Set.new
      @source_hash = {}
      @cache_hash = {}
      @fully_loaded = false
    end

    # Verify that all the keys marked as required are present.
    # @raise RequiredAttribute if a required attribute is missing
    # @return [void]
    def verify_required!
      @key_metadata.required_properties.each do |key_name|
        next if @source_hash.key?(@key_metadata.get(key_name).source_key)
        raise RequiredAttribute, "#{@parent} requires `#{key_name}`"
      end
    end

    # @return [Array] the identity properties
    def required_properties
      @key_metadata.required_properties
    end

    # Converts all unconverted keys and packages them as a hash.
    # @return [Hash] the converted hash
    def parent_to_h
      todo = @key_metadata.keys - @cache_hash.keys
      todo.each_with_object(@cache_hash) { |key, cache| cache[key] = load_key_from_source(key) }.dup
    end

    # @return [String] the string representation of the parent
    def parent_inspect
      "#<#{@parent.class.name} (#{@fully_loaded ? 'loaded' : 'unloaded'}): [" + \
        @cache_hash.keys.join(', ') + ']>'
    end

    # Mark a key as tainted, forcing a reload on the next lookup.
    # @param key_name [Symbol] the key to invalidate
    # @return [void]
    def invalidate(key_name)
      @invalidated.add(key_name)
    end

    # Get the value of a key (fetching it from the cache if possible)
    # @param key_name [Symbol] the name of the key
    # @return [Object] the returned value
    # @raise MissingAttribute if the attribute wasn't found and there isn't a default
    def read_attribute(key_name)
      if @invalidated.include?(key_name)
        @parent.reload
        @invalidated.delete(key_name)
      end
      @cache_hash[key_name] ||= load_key_from_source(key_name)
    end

    # Update an attribute.
    # @param key_name [Symbol] the attribute to update
    # @param new_value [Object] the new value
    # @return [Object] the written value
    def write_attribute(key_name, new_value)
      unless @key_metadata.contains?(key_name)
        raise ArgumentError, "#{key_name} is not a valid attribute for #{parent}"
      end
      @cache_hash[key_name] = new_value
    end

    # Merge a hash into the model.
    # @param attributes [Hash<Symbol, Object>] the attributes to merge
    def merge!(attributes)
      @cache_hash.clear
      @source_hash.merge!(attributes)
    end

    private

    # Load the key and apply transformations to it, skipping the cache.
    # @param key_name [Symbol] the key name
    # @return [Object] the returned value
    # @raise MissingAttribute if the attribute wasn't found and there isn't a default
    def load_key_from_source(key_name)
      meta = ensure_metadata_exists(key_name)
      ensure_key_is_loaded(meta.source_key, meta.runtime_required?)
      raw_value = @source_hash.fetch(meta.source_key) { fetch_default(meta.default) }
      transform_value(raw_value, meta.transform)
    end

    # Ensure the metadata is found.
    # @param key_name [Symbol] the property name
    # @return [KeyMetadata] the key metadata, if found
    # @raise MissingAttribute if the key metadata wasn't found
    def ensure_metadata_exists(key_name)
      return @key_metadata.get(key_name) if @key_metadata.contains?(key_name)
      raise MissingAttribute, "`#{key_name}` isn't defined for #{@parent}"
    end

    # Reloads the model if a key isn't loaded and possibly errors if the key still isn't there.
    # @param source_key [Symbol] the key that should be loaded
    # @param runtime_required [Boolean] whether to raise an error if the key is not loaded
    # @return [void]
    # @raise MissingAttribute if runtime_required is true and the key can't be loaded.
    def ensure_key_is_loaded(source_key, runtime_required)
      @parent.reload if !@source_hash.key?(source_key) && !@fully_loaded
      return if @source_hash.key?(source_key) || !runtime_required
      raise MissingAttribute, "`#{source_key} is missing for #{@parent}`"
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
