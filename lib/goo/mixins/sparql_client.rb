class String
  def to_uri
    return self
  end
end

module RDF
  def self.URI(*args, &block)
    return RDF::URI.new(*args)
  end

  class URI
    # Delegate any undefined method calls to the String object
    def method_missing(method, *args, &block)
      if self.to_s.respond_to?(method)
        self.to_s.send(method, *args, &block)
      else
        super
      end
    end

    # Ensure respond_to? reflects the delegated methods
    def respond_to_missing?(method, include_private = false)
      self.to_s.respond_to?(method) || super
    end

  end

  class Writer
    def validate?
      false
    end
  end

  class Literal
    def to_base
      text = []
      text << %("#{escape(value)}")
      text << "@#{language}" if has_language?
      if has_datatype?
        if datatype.respond_to?:to_base
          text << "^^#{datatype.to_base}"
        else
          text << "^^<#{datatype.to_s}>"
        end
      end
      text.join ""
    end
  end


  class Literal
    class DateTime < Temporal
      FORMAT = '%Y-%m-%dT%H:%M:%S'.freeze # the format that is supported by 4store
    end
  end
end #end RDF
