module EleetScript
  class RubyToEleetWrapper
    def initialize(ruby_obj, engine, options = {})
      @ruby_obj = ruby_obj
      @engine = engine
      @options = options
      if @options[:lock]
        @options[:lock] = [@options[:lock]] unless @options[:lock].kind_of?(Array)
      end
      if @options[:allow]
        @options[:allow] = [@options[:allow]] unless @options[:allow].kind_of?(Array)
      end
    end

    def call(method_name, args = [])
      unless can_call_method?(method_name)
        @engine["Errors"] < "Attempt to call locked method \"#{method_name}\" failed."
        return Values.to_eleet_value(@engine["nil"], @engine)
      end
      if method_name.to_sym == :to_string
        method_name = :to_s
      elsif method_name.to_sym == :class_ref
        method_name = :class
      elsif method_name.to_sym == :class_name
        cls = if @ruby_obj.class == Class
          @ruby_obj
        else
          @ruby_obj.class
        end
        return Values.to_eleet_value(cls.name, @engine)
      end
      ruby_args = args.map { |arg| Values.to_ruby_value(arg, @engine) }
      block = if ruby_args.length > 0 && ruby_args.last.is_a?(RubyLambda)
        ruby_args.pop
      else
        nil
      end
      begin
        Values.to_eleet_value(@ruby_obj.send(method_name, *ruby_args, &block), @engine)
      rescue NoMethodError => e
        Values.to_eleet_value(@engine["nil"], @engine)
      end
    end

    def can_call_method?(method_name)
      method_name = method_name.to_sym
      # Check our options first, they can override class defined locks/allows.
      if @options[:allow]
        if @options[:allow].include?(method_name)
          return true
        else
          return false
        end
      end
      if @options[:lock]
        if @options[:lock].include?(method_name)
          return false
        else
          return true
        end
      end
      # Check the Whitelist
      if @ruby_obj.respond_to?(:eleetscript_allow_methods)
        val = @ruby_obj.eleetscript_allow_methods
        return false if val == :none
        return true if val == :all
        if val.kind_of?(Array) && val.include?(method_name)
          return true
        else
          return false
        end
      end
      # Check the Blacklist
      if @ruby_obj.respond_to?(:eleetscript_lock_methods)
        val = @ruby_obj.eleetscript_lock_methods
        return true if val == :none
        return false if val == :all
        if val.kind_of?(Array) && val.include?(method_name)
          return false
        else
          return true
        end
      end
      # If not specifically allowed/denied, then it can be accessed.
      true
    end

    def raw
      @ruby_obj
    end

    def is_a?(name)
      cls = if @ruby_obj.class == Class
        @ruby_obj
      else
        @ruby_obj.class
      end
      cls_names = cls.ancestors.map do |a|
        if a.name.nil?
          nil
        else
          a.name.split("::").last
        end
      end
      cls_names.compact.include?(name)
    end

    def class?
      Values.to_eleet_value(@ruby_obj.class == Class, @engine)
    end

    def instance?
      !class?
    end

    def name
      if @ruby_obj.class == Class
        @ruby_obj.name
      else
        @ruby_obj.class.name
      end
    end

    def runtime_class
      cls = if @ruby_obj.class == Class
        @ruby_obj
      else
        @ruby_obj.class
      end
      Values.to_eleet_value(cls)
    end
  end
end
