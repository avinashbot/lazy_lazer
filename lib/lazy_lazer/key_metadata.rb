# frozen_string_literal: true

require_relative 'errors'

module LazyLazer
  # Simple PORO for key metadata. Yay value objects!
  class KeyMetadata
    attr_reader :source_key
    attr_reader :default
    attr_reader :transform

    def initialize(source_key:, required:, runtime_required:, default:, transform:)
      @source_key = source_key
      @required = required
      @runtime_required = runtime_required
      @default = default
      @transform = transform
      freeze
    end

    def required?
      @required
    end

    def runtime_required?
      @runtime_required
    end

    def transform_value(value, context)
      case @transform
      when nil
        value
      when Proc
        context.instance_exec(value, &@transform)
      when Symbol
        value.public_send(@transform)
      end
    end

    def fetch_default(context)
      return context.instance_exec(&@default) if @default.is_a?(Proc)
      @default
    end
  end
end
