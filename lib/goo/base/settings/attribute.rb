module Goo
  module Base
    module Settings
      module AttributeSettings

        def attribute(*args)
          options = args.reverse
          attr_name = options.pop
          attr_name = attr_name.to_sym
          options = options.pop
          options = {} if options.nil?

          options[:enforce] ||= []

          set_data_type(options)
          set_no_list_by_default(options)

          @model_settings[:attributes][attr_name] = options
          load_yaml_scheme_options(attr_name)
          shape_attribute(attr_name)
          namespace = attribute_namespace(attr_name) || @model_settings[:namespace]
          vocab = Goo.vocabulary(namespace)
          if options[:property].is_a?(Proc)
            @attribute_uris[attr_name] = options[:property]
          else
            @attribute_uris[attr_name] = vocab[options[:property] || attr_name]
          end
          if options[:enforce].include?(:unique) && options[:enforce].include?(:list)
            raise ArgumentError, ":list options cannot be combined with :list"
          end
          set_range(attr_name)
        end

        def shape_attribute(attr)
          return if attr == :resource_id

          attr = attr.to_sym
          define_method("#{attr}=") do |*args|
            if self.class.handler?(attr)
              raise ArgumentError, "Method based attributes cannot be set"
            end
            if self.class.inverse?(attr) && !(args && args.last.instance_of?(Hash) && args.last[:on_load])
              raise ArgumentError, "`#{attr}` is an inverse attribute. Values cannot be assigned."
            end
            @loaded_attributes.add(attr)
            value = args[0]
            unless args.last.instance_of?(Hash) and args.last[:on_load]
              if self.persistent? and self.class.name_with == attr
                raise ArgumentError, "`#{attr}` attribute is used to name this resource and cannot be modified."
              end
              prev = self.instance_variable_get("@#{attr}")
              if !prev.nil? and !@modified_attributes.include?(attr)
                if prev != value
                  @previous_values = @previous_values || {}
                  @previous_values[attr] = prev
                end
              end
              @modified_attributes.add(attr)
            end
            if value.instance_of?(Array)
              value = value.dup.freeze
            end
            self.instance_variable_set("@#{attr}", value)
          end
          define_method("#{attr}") do |*args|
            attr_value = self.instance_variable_get("@#{attr}")

            if self.class.not_show_all_languages?(attr_value, args)
              is_array = attr_value.values.first.is_a?(Array)
              attr_value = attr_value.values.flatten
              attr_value = attr_value.first unless is_array
            end

            if self.class.handler?(attr)
              if @loaded_attributes.include?(attr)
                return attr_value
              end
              value = self.send("#{self.class.handler(attr)}")
              self.instance_variable_set("@#{attr}", value)
              @loaded_attributes << attr
              return value
            end

            if (not @persistent) or @loaded_attributes.include?(attr)
              return attr_value
            else
              # TODO: bug here when no labels from one of the main_lang available... (when it is called by ontologies_linked_data ontologies_submission)
              raise Goo::Base::AttributeNotLoaded, "Attribute `#{attr}` is not loaded for #{self.id}. Loaded attributes: #{@loaded_attributes.inspect}."
            end
          end
        end

        def attributes(*options)
          if options and options.length > 0
            option = options.first

            if option == :all
              return @model_settings[:attributes].keys
            end

            if option == :inverse
              return @model_settings[:attributes].select { |_, v| v[:inverse] }.keys
            end

            attrs = @model_settings[:attributes].select { |_, opts| opts[:enforce].include?(option) }.keys

            attrs.concat(attributes(:inverse)) if option == :list

            return attrs
          end

          @model_settings[:attributes].select { |k, attr| attr[:inverse].nil? && !handler?(k) }.keys

        end

        def attributes_with_defaults
          @model_settings[:attributes].select { |_, opts| opts[:default] }.keys
        end

        def attribute_namespace(attr)
          attribute_settings(attr)[:namespace]
        end

        def default(attr)
          attribute_settings(attr)[:default]
        end

        def range(attr)
          @model_settings[:range][attr]
        end

        def attribute_settings(attr)
          @model_settings[:attributes][attr]
        end

        def required?(attr)
          return false if attribute_settings(attr).nil?
          attribute_settings(attr)[:enforce].include?(:existence)
        end

        def unique?(attr)
          return false if attribute_settings(attr).nil?
          attribute_settings(attr)[:enforce].include?(:unique)
        end

        def datatype(attr)
          enforced = attribute_settings(attr)[:enforce].dup
          return :string if enforced.nil?

          enforced.delete(:list)
          enforced.delete(:no_list)

          enforced.find { |e| Goo::Validators::DataType.ids.include?(e) } || :string
        end

        def list?(attr)
          return false if attribute_settings(attr).nil?
          attribute_settings(attr)[:enforce].include?(:list)
        end

        def transitive?(attr)
          return false unless @model_settings[:attributes].include?(attr)
          attribute_settings(attr)[:transitive] == true
        end

        def alias?(attr)
          return false unless @model_settings[:attributes].include?(attr)
          attribute_settings(attr)[:alias] == true
        end

        def handler?(attr)
          return false if attribute_settings(attr).nil?
          !attribute_settings(attr)[:handler].nil?
        end

        def handler(attr)
          return false if attribute_settings(attr).nil?
          attribute_settings(attr)[:handler]
        end

        def inverse?(attr)
          return false if attribute_settings(attr).nil?
          !attribute_settings(attr)[:inverse].nil?
        end

        def inverse_opts(attr)
          attribute_settings(attr)[:inverse]
        end

        def attribute_uri(attr, *args)
          attr = attr.to_sym
          if attr == :id
            raise ArgumentError, ":id cannot be treated as predicate for .where, use find "
          end
          uri = @attribute_uris[attr]
          if uri.is_a?(Proc)
            uri = uri.call(*args.flatten)
          end
          return uri unless uri.nil?
          attr_string = attr.to_s
          Goo.namespaces.keys.each do |ns|
            nss = ns.to_s
            if attr_string.start_with?(nss)
              return Goo.vocabulary(ns)[attr_string[nss.length + 1..-1]]
            end
          end

          Goo.vocabulary(nil)[attr]
        end


        def indexable?(attr)
          setting = attribute_settings(attr.to_sym)
          setting  && (setting[:index].nil? || setting[:index] == true)
        end

        def fuzzy_searchable?(attr)
          attribute_settings(attr)[:fuzzy_search] == true
        end


        private

        def set_no_list_by_default(options)
          if options[:enforce].nil? or !options[:enforce].include?(:list)
            options[:enforce] = options[:enforce] ? (options[:enforce] << :no_list) : [:no_list]
          end
        end

        def set_data_type(options)
          if options[:type]
            options[:enforce] += Array(options[:type])
            options[:enforce].uniq!
            options.delete :type
          end
        end
      end
    end
  end
end
