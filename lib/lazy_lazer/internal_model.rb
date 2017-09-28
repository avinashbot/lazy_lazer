# frozen_string_literal: true

module LazyLazer
  # A delegator for internal operations.
  class InternalModel
    # Create an internal model with a reference to a public model.
    # @param key_metadata [Hash<Symbol, KeyMetadata>] a reference to a property hash
    # @param parent [LazyLazer] a reference to a LazyLazer model
    def initialize(key_metadata, parent)
      @key_metadata = key_metadata
      @parent = parent
      @source_hash = {}
      @cache_hash = {}
    end

    # Verify that all the keys marked as required are present.
    # @raise RequiredAttribute if a required attribute is missing
    # @return [void]
    def verify_required!
      @key_metadata.each do |key_name, meta|
        next if !meta.required? || @source_hash.key?(meta.source_key)
        raise RequiredAttribute, "#{@parent} requires `#{key_name}`"
      end
    end

    # Converts all unconverted keys and packages them as a hash.
    # @return [Hash] the converted hash
    def to_h
      todo = @key_metadata.keys - @cache_hash.keys
      todo.each_with_object(@cache_hash) { |key, cache| cache[key] = load_key_from_source(key) }.dup
    end

    # Get the value of a key (fetching it from the cache if possible)
    # @param key_name [Symbol] the name of the key
    # @return [Object] the returned value
    # @raise MissingAttribute if the attribute wasn't found and there isn't a default
    def fetch(key_name)
      @cache_hash[key_name] ||= load_key_from_source(key_name)
      @cache_hash[key_name]
    end

    # Merge a hash into the model.
    # @param attributes [Hash<Symbol, Object>] the attributes to merge
    # @return [nil]
    def merge!(attributes)
      @cache_hash.clear
      @source_hash.merge!(attributes)
      nil
    end

    private

    # Load the key and apply transformations to it, skipping the cache.
    # @param key_name [Symbol] the key name
    # @return [Object] the returned value
    # @raise MissingAttribute if the attribute wasn't found and there isn't a default
    def load_key_from_source(key_name)
      # Check if the property is defined.
      meta = @key_metadata.fetch(key_name) do
        raise MissingAttribute, "`#{key_name}` isn't defined for #{@parent}"
      end

      # Reload the model if necessary.
      @parent.reload if !@source_hash.key?(meta.source_key) && !@parent.fully_loaded?
      if !@source_hash.key?(meta.source_key) && meta.runtime_required?
        raise MissingAttribute, "`#{meta.source_key} is missing for #{@parent}`"
      end

      # Process the value.
      raw_value = @source_hash.fetch(meta.source_key) { fetch_default(meta.default) }
      transform_value(raw_value, meta.transform)
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
