# frozen_string_literal: true

require_relative 'errors'

module LazyLazer
  # A container of sorts for model properties.
  class Properties
    def initialize(model, attributes)
      @model = model
      @attributes = attributes.dup
    end

    def default_behaviour
      ->() { raise MissingAttribute, "`#{key}` isn't found for #{self}" }
    end

    def transform_behaviour
      ->(value) { value }
    end

    def extract(source_key:, transform: transform_behaviour, default: default_behaviour)
      raw_value = @attributes.fetch(source_key) { @model.instance_exec(&default) }
      @model.instance_exec(raw_value, &transform)
    end
  end
end
