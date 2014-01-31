require "lang/runtime/class_skeleton"
require "lang/runtime/class_instance"
require "lang/runtime/method_hash"
require "util/processed_key_hash"

module EleetScript
  class EleetScriptClass < EleetScriptClassSkeleton
    attr_accessor :methods, :class_vars, :context, :name
    attr_reader :super_class
    set_is_class

    class << self
      def create(namespace, name, super_class = nil)
        cls = EleetScriptClass.new(namespace, super_class)
        cls.name = name
        cls
      end
    end

    def initialize(namespace, super_class = nil)
      @methods = MethodHash.new
      @class_vars = ProcessedKeyHash.new
      @class_vars.set_key_preprocessor do |key|
        key[0..1] == "@@" ? key[2..-1] : key
      end
      @context = namespace.new_class_context(self, self)
      @super_class = super_class
      @ruby_value = self
    end
    alias :class_name :name

    def call(method_name, arguments = [])
      method = lookup(method_name.to_s)
      if method
        if method.arity == 3
          method.call(self, arguments, @context)
        else
          method.call(self, arguments)
        end
      else
        es_method_name = @context["String"].new_with_value(method_name.to_s)
        call(NO_METHOD, arguments.dup.unshift(es_method_name))
      end
    end

    def lookup(method_name)
      method_name = method_name[0..1] == "@@" ? method_name : "@@#{method_name}"
      method = @methods[method_name]
      if method.nil? && has_super_class?
        return super_class.lookup(method_name)
      end
      method
    end

    def instance_lookup(method_name)
      method = @methods[method_name]
      if method.nil? && has_super_class?
        return super_class.instance_lookup(method_name)
      end
      method
    end

    def super_class
      @super_class || @context["Object"]
    end

    def def(method_name, es_block = nil, &block)
      method_name = method_name.to_s
      if block_given?
        @methods[method_name] = block
      else
        @methods[method_name] = es_method
      end
    end

    def class_def(method_name, es_block = nil, &block)
      method_name = "@@#{method_name}"
      if block_given?
        @methods[method_name] = block
      else
        @methods[method_name] = es_method
      end
    end

    def new
      EleetScriptClassInstance.new(@context, self)
    end

    def new_with_value(value)
      cls = EleetScriptClassInstance.new(@context, self)
      cls.ruby_value = value
      cls
    end

    def to_s
      "<EleetScriptClass \"#{name || "Unnamed"}\">"
    end

    def inspect
      to_s[0..-2] + " @methods(#{@methods.keys.join(", ")})>"
    end

    def is_a?(value)
      false
    end

    private

    def has_super_class?
      @super_class || (@super_class.nil? && name != "Object")
    end
  end
end