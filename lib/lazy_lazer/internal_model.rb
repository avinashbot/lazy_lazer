# frozen_string_literal: true

module LazyLazer
  # A delegator for internal operations.
  class InternalModel
    def initialize(key_metadata, parent)
      @key_metadata = key_metadata
      @parent = parent
      @source_hash = {}
      @cache_hash = {}
    end

    def verify_required!
      @key_metadata.each do |key_name, meta|
        next if !meta.required? || @source_hash.key?(meta.source_key)
        raise RequiredAttribute, "#{@parent} requires `#{key_name}`"
      end
    end

    def to_h
      todo = @key_metadata.keys - @cache_hash.keys
      todo.each_with_object(@cache_hash) { |key, cache| cache[key] = load_key_from_source(key) }
    end

    def fetch(key_name)
      @cache_hash[key_name] ||= load_key_from_source(key_name)
      @cache_hash[key_name]
    end

    def merge!(attributes)
      @cache_hash.clear
      @source_hash.merge!(attributes)
    end

    private

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

    def fetch_default(default)
      return @parent.instance_exec(&default) if default.is_a?(Proc)
      default
    end
  end
end
