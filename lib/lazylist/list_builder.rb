require 'dslkit'

class LazyList
  def do_build(lb, others) # :nodoc:
    if empty? or others.any? { |o| o.empty? }
      Empty
    else
      variables = [ head ].concat others.map { |o| o.head }
      if lb.filter
        if lb.filter[*variables]
          self.class.new(lb.transform[*variables]) do
            tail.do_build(lb, others.map { |o| o.tail })
          end
        else
          tail.do_build(lb, others.map { |o| o.tail })
        end
      else
        self.class.new(lb.transform[*variables]) do
          tail.do_build(lb, others.map { |o| o.tail })
        end
      end
    end
  end

  def do_comprehend(lb, others) # :nodoc:
    if lb.filter
      cartesian_product(*others).select do |variables|
        lb.filter[*variables]
      end.map do |variables|
        lb.transform[*variables]
      end
    else
      cartesian_product(*others).map do |variables|
        lb.transform[*variables]
      end
    end
  end

  # This class encapsulates a list builder (ListBuilder), that can be transformed
  # into a LazyList, by calling LazyList::ListBuilder#where.
  class ListBuilder
    # This class is a special kind of Proc object, that uses instance_eval to
    # execute a code block.
    class ListBuilderProc < Proc
      include DSLKit::MethodMissingDelegator
      include DSLKit::BlockSelf

      # Creates a ListBuilderProc working on the list builder _lb_ using the Proc
      # returned by lb.#{name}. _name_ has to be either :filter or :transform.
      def initialize(lb, name, &block)
        @name = name
        @lb = lb
        @method_missing_delegator = block_self(&block)
        super(&@lb.__send__(@name))
      end

      # Call this ListBuilderProc instance with the arguments _args_, which have to be
      # the ordered values of the variables.
      def call(*args)
        prepare_variables
        @lb.variables.each_with_index do |var, i|
          instance_variable_set "@#{var}", args[i]
        end
        instance_eval(&@lb.__send__(@name))
      end
      alias [] call

      private

      def prepare_variables
        @variables_prepared and return
        variables = @lb.variables
        class << self; self; end.instance_eval do
          attr_reader(*variables)
        end
        @variables_prepared = true
      end
    end

    # Creates LazyList::ListBuilder instance. _mode_ has to be either :do_build
    # or :do_comprehend.
    def initialize(mode, &block)
      @mode = mode
      @transform = ListBuilderProc.new(self, :transform, &block)
    end

    # The variable names defined in this list builder.
    attr_reader :variables

    # The transform ListBuilderProc instance of this list builder.
    attr_reader :transform

    # The filter ListBuilderProc of this list builder or nil.
    attr_reader :filter

    # This method creates a LazyList instance from this list builder,
    # using the _sources_ hash to fetch the variables from. _sources_ consists
    # of the variable name and the values, that can be LazyList instances or
    # otherwise they will be transformed into a LazyList with LazyList.[].
    #
    # It also takes a block, to filter the results by a boolean expression.
    def where(sources = {}, &block)
      @variables = []
      generators = []
      sources.each do |var, src|
        @variables << var
        generators << (src.is_a?(LazyList) ? src : LazyList[src])
      end
      if block_given?
        @filter = ListBuilderProc.new(self, :filter, &block)
      else
        @filter = nil
      end
      generators.first.__send__(@mode, self, generators[1..-1])
    end

    # Return a (not much) nicer string representation of the list
    # builder.
    def to_s
      "#<LazyList::ListBuilder>"
    end
    alias inspect to_s

    class << self
      # Used to support the build method
      def create_build(&block)
        new(:do_build, &block)
      end

      # Used to evaluate a list comprehension, usually if calling the list
      # method with only a block.
      def create_comprehend(&block)
        new(:do_comprehend, &block)
      end
    end
  end
end
