module MinimumTerm
  class Object
    attr_reader :service, :name, :schema
    def initialize(service, scoped_name, schema)
      @service = service
      @name = scoped_name
      @scoped_name = remove_service_from_scoped_name(scoped_name)
      @schema = schema
    end

    private

    def remove_service_from_scoped_name(n)
      n[n.index(MinimumTerm::SCOPE_SEPARATOR)+1..-1]
    end

  end
end
