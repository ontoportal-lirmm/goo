class String
  def to_uri
    return self
  end
end

module RDF
  def self.URI(*args, &block)
    return args.first
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
    @@subclasses_by_uri = {}
    def self.datatyped_class(uri)
      return nil if uri.nil?
      if @@subclasses.length != (@@subclasses_by_uri.length + 1)
       @@subclasses.each do |child|
        if child.const_defined?(:DATATYPE)
          @@subclasses_by_uri[child.const_get(:DATATYPE).to_s] = child
        end
       end
      end
      return @@subclasses_by_uri[uri]
    end
  end
end #end RDF
