require 'active_support'


module RailheadMemorize

  def self.included(base)
    base.extend ClassMethods
  end

  module ClassMethods

    def memorize(key, options = {})
      class_eval <<-END
        alias #{key}_unmemorized #{key}
        before_create :initialize_memorized_#{key}

        def initialize_memorized_#{key}
          self.memorized_#{key} = #{options[:default] ? options[:default].inspect : '[]'}.to_msgpack if respond_to?(:memorized_#{key})
        end

        def memorize_#{key}
          update_attribute :memorized_#{key}, #{key}_unmemorized.to_msgpack if respond_to?(:memorized_#{key})
        end

        def #{key}
          @#{key} ||= if respond_to?(:memorized_#{key})
            if not memorized_#{key}.blank?
              MessagePack.unpack(memorized_#{key})
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

