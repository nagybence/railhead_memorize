require 'active_support'
require 'multi_json'


module RailheadMemorize

  def self.included(base)
    base.extend ClassMethods
  end

  module ClassMethods

    def memorize(key, options = {})
      options.reverse_merge! :on_view => true
      class_eval <<-END
        alias #{key}_unmemorized #{key}
        before_create :initialize_memorized_#{key}

        def initialize_memorized_#{key}
          self.memorized_#{key} = MultiJson.dump(#{options[:default] ? options[:default].inspect : '[]'}) if respond_to?(:memorized_#{key})
        end

        def memorize_#{key}
          update_column :memorized_#{key}, MultiJson.dump(#{key}_unmemorized) if respond_to?(:memorized_#{key}) and not frozen?
        end

        def #{key}
          @#{key} ||= if respond_to?(:memorized_#{key})
            if not memorized_#{key}.blank?
              begin
                MultiJson.load(memorized_#{key})
              rescue
                memorize_#{key}
                #{key}
              end
            elsif #{!!options[:on_view]}
              memorize_#{key}
              #{key}
            else
              #{key}_unmemorized
            end
          else
            #{key}_unmemorized
          end
        end
      END
    end
  end
end


module RailheadMemorizeLoader

  def self.included(base)
    base.extend ClassMethods
  end

  module ClassMethods

    def use_memorize
      include RailheadMemorize
    end
  end
end


ActiveRecord::Base.send :include, RailheadMemorizeLoader
