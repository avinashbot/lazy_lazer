# frozen_string_literal: true

module LazyLazer
  # The key metadata collection class
  class KeyMetadataStore
    # @return [Array<Symbol>] the required properties
    attr_reader :required_properties

    def initialize
      @collection = {}
      @required_properties = []
    end

    # Used for {Object#dup}.
    def initialize_copy(original)
      super
      @collection = original.instance_variable_get(:@collection).dup
      @required_properties = original.instance_variable_get(:@required_properties).dup
    end

    # Add a KeyMetadata to the store.
    # @param key [Symbol] the key
    # @param meta [KeyMetadata] the key metadata
    # @return [KeyMetadata] the provided meta
    def add(key, meta)
      @collection[key] = meta
      if meta.required?
        @required_properties << key
      else
        @required_properties.delete(key)
      end
      meta
    end

    # @return [Array<Symbol>] the keys in the store
    def keys
      @collection.keys
    end

    # @return [Boolean] whether the store contains the key
    def contains?(key)
      @collection.key?(key)
    end

    # @return [KeyMetadata] fetch the metadata from the store
    def get(key)
      @collection.fetch(key)
    end
  end
end
