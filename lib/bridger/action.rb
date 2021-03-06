require "parametric/dsl"

module Bridger
  class ValidationErrors < StandardError
    attr_reader :errors

    def initialize(errors)
      @errors = errors
      super
    end
  end

  class Action
    include Parametric::DSL

    def self.run!(*args)
      new(*args).call
    end

    def self.payload(*args, &block)
      self.schema *args, &block
    end

    def self.query(*args, &block)
      self.schema *(args.unshift(:query)), &block
    end

    def initialize(query: {}, payload: {}, auth: nil)
      @_query = query
      @_payload = payload
      @auth = auth
    end

    def payload
      @payload ||= map(payload_validator.output)
    end

    def query
      @query ||= map(query_validator.output)
    end

    def params
      @params ||= query.merge(payload)
    end

    def call
      if !payload_validator.valid?
        raise ValidationErrors.new(payload_validator.errors)
      end
      if !query_validator.valid?
        raise ValidationErrors.new(query_validator.errors)
      end

      run!
    end

    private
    attr_reader :_query, :_payload, :auth

    def run!

    end

    def payload_validator
      @payload_validator ||= self.class.payload.resolve(_payload)
    end

    def query_validator
      @query_validator ||= self.class.query.resolve(_query)
    end

    def schema
      self.class.payload
    end

    def map(hash)
      hash
    end
  end
end
