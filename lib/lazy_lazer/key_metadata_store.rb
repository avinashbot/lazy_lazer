# frozen_string_literal: true

module LazyLazer
  # The key metadata collection class
  class KeyMetadataStore
    # @return [Array<Symbol>] the required properties
    attr_reader :required_properties

    # @return [Array<Symbol>] the identity properties
    attr_reader :identity_properties

    def initialize
      @collection = {}
      @required_properties = []
      @identity_properties = []
    end

    # Add a KeyMetadata to the store.
    # @param key [Symbol] the key
    # @param meta [KeyMetadata] the key metadata
    # @return [KeyMetadata] the provided meta
    def add(key, meta)
      @collection[key] = meta
      @required_properties << key if meta.required?
      @identity_properties << key if meta.identity?
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
