# frozen_string_literal: true

module LazyLazer
  # The base class for all model errors.
  class ModelError < StandardError; end

  # This is raised when a required attribute isn't included.
  class RequiredAttribute < ModelError; end

  # Raised when a missing attribute is called but a default isn't present.
  class MissingAttribute < ModelError; end
end
