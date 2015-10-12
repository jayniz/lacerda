module MinimumTerm
  class ObjectDescription
    attr_reader :service, :name, :schema
    def initialize(defined_in_service, scoped_name, schema)
      @defined_in_service = defined_in_service
      @scoped_name = scoped_name
      @name = remove_service_from_scoped_name(scoped_name)
      @schema = schema
    end

    def service
      i = @scoped_name.index(MinimumTerm::SCOPE_SEPARATOR)
      return @defined_in_service unless i > 0
      @defined_in_service.infrastructure.services[@scoped_name[0...i].underscore.to_sym]
    end

    private

    def remove_service_from_scoped_name(n)
      n[n.index(MinimumTerm::SCOPE_SEPARATOR)+1..-1]
    end

  end
end
