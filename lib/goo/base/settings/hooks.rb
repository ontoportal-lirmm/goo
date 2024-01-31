require 'yaml'
require_relative '../../utils/callbacks_utils'

module Goo
  module Base
    module Settings
      module Hooks

        include CallbackRunner

        def after_save(*methods)
          @model_settings[:after_save] ||= []
          @model_settings[:after_save].push(*methods)
        end

        def after_destroy(*methods)
          @model_settings[:after_destroy] ||= []
          @model_settings[:after_destroy].push(*methods)
        end

        def after_save_callbacks
          Array(@model_settings[:after_save])
        end

        def after_destroy_callbacks
          Array(@model_settings[:after_destroy])
        end

        def after_save?
          !after_save_callbacks.empty?
        end

        def after_destroy?
          !after_destroy_callbacks.empty?
        end

        def call_after_save(inst)
          run_callbacks(inst, after_save_callbacks)
        end

        def call_after_destroy(inst)
          run_callbacks(inst, after_destroy_callbacks)
        end

        def attributes_with_callbacks
          (@model_settings[:attributes].
            select{ |attr,opts| opts[:onUpdate] }).keys
        end


        def attribute_callbacks(attr)
          @model_settings[:attributes][attr][:onUpdate]
        end

      end
    end
  end
end




