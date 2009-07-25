class LazyList
  require 'dslkit'
  require 'lazylist/list_builder'
  require 'lazylist/version'

  require 'lazylist/enumerable'
  include LazyList::Enumerable

  # Exceptions raised by the LazyList implementation.
  class Exception < ::StandardError; end

  if defined?(::Enumerator)
    require 'lazylist/enumerator_queue.rb'
  else
    require 'lazylist/thread_queue.rb'
  end

  Promise = DSLKit::BlankSlate.with :inspect, :to_s # :nodoc:
  # A promise that can be evaluated on demand (if forced).
  class Promise
    def initialize(&block)
      @block = block
    end

    # Return the value of this Promise.
    def __value__
      case v = @block.call
      when Promise
        v.__value__
      else
        v
      end
    end

    # Redirect all missing methods to the value of this Promise.
    def method_missing( *args, &block )
      __value__.__send__( *args, &block )
    end
  end

  # A promise that can be evaluated on demand (if forced), that caches its
  # value.
  class MemoPromise < Promise
    # Return the value of this Promise and memoize it for later access.
    def __value__
      if defined?(@value)
        @value
      else
        @value = super
      end
    end
  end  

  # This module contains module functions, that are added to LazyList and it's
  # instances.
  module ModuleFunctions
    # Delay the value of _block_ to a Promise.
    def delay(&block)
      MemoPromise.new(&block)
    end

    # Force the delayed _obj_ to evaluate to its value. 
    def force(obj)
      case obj
      when Promise
        force obj.__value__
      else
        obj
      end
    end

    # Returns a LazyList, that consists of the mixed elements of the lists
    # _lists without any special order.
    def mix(*lists)
      return empty if lists.empty?
      first = lists.shift
      if lists.empty?
        first
      elsif first.empty?
        mix(*lists)
      else
        LazyList.new(first.head) do
          t = first.tail
          lists = lists.push t unless t.empty?
          mix(*lists)
        end
      end
    end
  end
  extend ModuleFunctions
  include ModuleFunctions

  # Returns an empty list.
  def self.empty
    new(nil, nil)
  end

  # Returns an empty list.
  def empty
    @klass ||= self.class
    @klass.new(nil, nil)
  end

  # Creates a new LazyList element. The tail can be given either as
  # second argument or as block.
  def initialize(head = nil, tail = nil, &block)
    @cached = true
    @ref_cache = {}
    if tail
      if block
        raise LazyList::Exception,
          "Use block xor second argument for constructor"
      end
      @head, @tail = head, tail
    elsif block
      @head, @tail = head, delay(&block)
    else
      @head, @tail = nil, nil
    end
  end

  # Set this to false, if index references into the lazy list shouldn't be
  # cached for fast access (while spending some memory on this). This value
  # defaults to true.
  attr_writer :cached

  # Returns true, if index references into the lazy list are cached for fast
  # access to the referenced elements.
  def cached?
    !!@cached
  end

  # If the constant Empty is requested return a new empty list object.
  def self.const_missing(id)
    if id == :Empty
      new(nil, nil)
    else
      super
    end
  end

  # Returns the value of this element.
  attr_writer :head
  protected :head=

  # Returns the head of this list by computing its value.
  def head
    @head = force @head
  end

  # Returns the head of this list without forcing it.
  def peek_head
    @head
  end
  protected :peek_head

  # Writes a tail value.
  attr_writer :tail
  protected :tail=

  # Returns the next element by computing its value if necessary.
  def tail
    @tail = force @tail
  end

  # Returns the tail of this list without forcing it.
  def peek_tail
    @tail
  end
  protected :peek_tail

  # Identity lambda expression, mostly used as a default.
  Identity = lambda { |x| x }

  # This block returns true.
  All = lambda { |x| true }

  # Create an array tuple from argument list.
  Tuple = lambda { |*t| t }

  # Returns true, if a less than b.
  LessThan = lambda { |a, b| a < b }

  # Swaps _you_ and _me_ and returns an Array tuple of both.
  SwapTuple = lambda { |you, me| [ me, you ] }

  # Returns a lazy list which is generated from the Enumerable a or
  # LazyList.span(a, n), if n was given as an argument.
  def self.[](a, n = nil)
    case
    when n
      span(a, n)
    when a.respond_to?(:to_io)
      io(a.to_io)
    when a.respond_to?(:to_ary)
      from_queue(a.to_ary)
    when Range === a
      from_range(a)
    when a.respond_to?(:each)
      from_enum(a)
    else
      list(a)
    end
  end

  # Generates a lazy list from any data structure e which
  # responds to the #each method. 
  def self.from_enum(e)
    from_queue ReadQueue.new(e)
  end

  # Generates a lazyx list by popping elements from a queue.
  def self.from_queue(rq)
    return empty if rq.empty?
    new(delay { rq.shift }) { from_queue(rq) }
  end

  # Generates a lazy list from a Range instance _r_.
  def self.from_range(r)
    if r.exclude_end?
      if r.begin >= r.end
        empty
      else
        new(delay { r.begin }) { from_range(r.begin.succ...r.end) }
      end
    else
      case
      when r.begin > r.end
        empty
      when r.begin == r.end
        new(delay { r.begin }) { empty }
      else
        new(delay { r.begin }) { from_range(r.begin.succ..r.end) }
      end
    end
  end

  # Generates a finite lazy list beginning with element a and spanning
  # n elements. The data structure members have to support the
  # successor method succ.
  def self.span(a, n)
    if n > 0
      new(delay { a }) { span(a.succ, n - 1) }
    else
      empty
    end
  end

  # Generates a lazy list which tabulates every element beginning with n
  # and succeding with succ by calling the Proc object f or the given block.
  # If none is given the identity function is computed instead.
  def self.tabulate(n = 0, &f)
    f = Identity unless f
    new(delay { f[n] }) { tabulate(n.succ, &f) }
  end

  # Returns a list of all elements succeeding _n_ (that is created by calling
  # the #succ method) and starting from _n_.
  def self.from(n = 0)
    tabulate(n)
  end
  
  # Generates a lazy list which iterates over its previous values
  # computing something like: f(i), f(f(i)), f(f(f(i))), ...
  def self.iterate(i = 0, &f)
    new(delay { i }) { iterate(f[i], &f) }
  end

  # Generates a lazy list of a give IO-object using a given
  # block or Proc object to read from this object.
  def self.io(input, &f)
    if f
      input.eof? ? empty : new(delay { f[input] }) { io(input, &f) }
    else
      input.eof? ? empty : new(delay { input.readline }) { io(input) }
    end
  end

  # Returns the sublist, constructed from the Range _range_ indexed elements,
  # of this lazy list.
  def sublist_range(range)
    f = range.first
    l = range.exclude_end? ? range.last - 1 : range.last
    sublist_span(f, l - f + 1)
  end

  # Returns the sublist, that spans _m_ elements starting from the _n_-th
  # element of this lazy list, if _m_ was given. If _m_ is non­positive, the
  # empty lazy list LazyList::Empty is returned.
  #
  # If _m_ wasn't given returns the _n_ long sublist starting from the first
  # (index = 0) element. If _n_ is non­positive, the empty lazy list
  # LazyList::Empty is returned.
  def sublist_span(n, m = nil)
    if not m
      sublist_span(0, n)
    elsif m > 0
      l = ref(n)
      self.class.new(delay { l.head }) { l.tail.sublist_span(0, m - 1) }
    else
      empty
    end
  end

  # Returns the result of sublist_range(n), if _n_ is a Range. The result of
  # sublist_span(n, m), if otherwise.
  def sublist(n, m = nil)
    if n.is_a? Range
      sublist_range(n)
    else
      sublist_span(n, m)
    end
  end

  def set_ref(n, value)
    return value unless cached?
    @ref_cache[n] = value
  end
  private :set_ref

  # Returns the n-th LazyList-Object.
  def ref(n)
    if @ref_cache.key?(n)
      return @ref_cache[n]
    end
    s = self
    i = n
    while i > 0 do
      if s.empty?
        return set_ref(n, self)
      end
      s.head # force the head
      s = s.tail
      i -= 1
    end
    set_ref(n, s)
  end
  protected :ref

  # If n is a Range every element in this range is returned.
  # If n isn't a Range object the element at index n is returned.
  # If m is given the next m elements beginning the n-th element are
  # returned.
  def [](n, m = nil)
    case
    when Range === n
      sublist(n)
    when n < 0
      nil
    when m
      sublist(n, m)
    else
      ref(n).head
    end
  end

  # Iterates over all elements. If n is given only n iterations are done.
  # If self is a finite lazy list each returns also if there are no more
  # elements to iterate over.
  def each(n = nil)
    s = self
    if n
      until n <= 0 or s.empty?
        yield s.head
        s = s.tail
        n -= 1 unless n.nil?
      end
    else
      until s.empty?
        yield s.head
        s = s.tail
      end
    end
    s
  end

  # Similar to LazyList#each but destroys elements from past iterations perhaps
  # saving some memory. Try to call GC.start from time to time in your block.
  def each!(n = nil)
    s = self
    if n
      until n <= 0 or s.empty?
        yield s.head
        s = s.tail
        n -= 1 unless n.nil?
        @head, @tail = s.head, s.tail
      end
    else
      until s.empty?
        yield s.head
        s = s.tail
        @head, @tail = s.head, s.tail
      end
    end
    self
  end

  # Merges this lazy list with the other. It uses the &compare block to decide
  # which elements to place first in the result lazy list. If no compare block
  # is given lambda { |a,b| a < b } is used as a default value.
  def merge(other, &compare)
    compare ||= LessThan
    case
    when empty?
      other
    when other.empty?
      self
    when compare[head, other.head]
      self.class.new(head) { tail.merge(other, &compare) }
    when compare[other.head, head]
      self.class.new(other.head) { merge(other.tail, &compare) }
    else
      self.class.new(head) { tail.merge(other.tail, &compare) }
    end
  end

  # Append this lazy list to the _*other_ lists, creating a new lists that
  # consists of the elements of this list and the elements of the lists other1,
  # other2, ... If any of the lists is infinite, the elements of the following
  # lists will never occur in the result list.
  def append(*other)
    if empty?
      if other.empty?
        empty
      else
        other.first.append(*other[1..-1])
      end
    else
      self.class.new(delay { head }) { tail.append(*other) }
    end
  end

  alias + append

  # Takes the next n elements and returns them as an array.
  def take(n = 1)
    result = []
    each(n) { |x| result << x }
    result
  end

  alias first take

  # Takes the _range_ indexes of elements from this lazylist and returns them
  # as an array.
  def take_range(range) 
    range.map { |i| ref(i).head }
  end

  # Takes the m elements starting at index n of this lazy list and returns them
  # as an array.
  def take_span(n, m)
    s = ref(n)
    s ? s.take(m) : nil
  end

  # Takes the next n elements and returns them as an array. It destroys these
  # elements in this lazy list. Also see #each! .
  def take!(n = 1)
    result = []
    each!(n) { |x| result << x }
    result
  end

  # Drops the next n elements and returns the rest of this lazy list. n
  # defaults to 1.
  def drop(n = 1)
    each(n) { }
  end

  # Drops the next n elements, destroys them in the lazy list and
  # returns the rest of this lazy list. Also see #each! .
  def drop!(n = 1)
    each!(n) { }
  end

  # Return the last +n+ elements of the lazy list. This is only sensible if the
  # lazy list is finite of course.
  def last(n = 1)
    to_a.last n
  end

  # Returns the size. This is only sensible if the lazy list is finite
  # of course.
  def size
    inject(0) { |s,| s += 1 }
  end

  alias length size

  # Returns true if this is the empty lazy list.
  def empty?
    self.peek_head == nil && self.peek_tail == nil
  end

  # Returns true, if this lazy list and the other lazy list consist of only
  # equal elements. This is only sensible, if the lazy lists are finite and you
  # can spare the memory.
  def eql?(other)
    other.is_a? self.class or return false
    size == other.size or return false
    to_a.zip(other.to_a) { |x, y| x == y or return false }
    true
  end
  alias == eql?

  # Inspects the list as far as it has been computed by returning
  # a string of the form [1, 2, 3,... ].
  def inspect
    return '[]' if empty?
    result = '['
    first = true
    s = self
    seen = {}
    until s.empty? or Promise === s.peek_head or seen[s.__id__]
      seen[s.__id__] = true
      if first
        first = false
      else
        result << ', '
      end
      result << s.head.inspect
      Promise === s.peek_tail and break
      s = s.tail
    end
    unless empty?
      if first
        result << '... '
      elsif !s.empty?
        result << ',... '
      end
    end
    result << ']'
  end

  alias to_s inspect

  # Returns one "half" of the product of this LazyList and the _other_:
  #  list(1,2,3).half_product(list(1,2)).to_a # => [[1, 1], [2, 1], [2, 2], [3, 1], [3, 2]]
  # _block_ can be used to yield to every pair generated and create a new list
  # element out of it. It defaults to Tuple.
  def half_product(other, &block)
    block ||= Tuple
    if empty? or other.empty?
      empty
    else
      mix(
        delay { zip(other, &block) },
        delay { tail.half_product(other, &block) }
      )
    end
  end

  def swap(block) # :nodoc:
    lambda { |you, me| block[me, you] }
  end
  private :swap

  # Returns the (cartesian) product of this LazyList instance and the _other_.
  # _block_ can be used to yield to every pair generated and create a new list
  # element out of it, but it's useful to at least return the default Tuple
  # from the block.
  def product(other, &block)
    if empty? or other.empty?
      empty
    else
      other_block =
        if block
          swap block
        else
          block = Tuple
          SwapTuple
        end
      mix(
        delay { half_product(other, &block)},
        delay { other.tail.half_product(self, &other_block) }
      )
    end
  end
  alias * product

  # Returns the cartesian_product of this LazyList and the others as a LazyList
  # of Array tuples. A block can be given to yield to all the created tuples
  # and create a LazyList out of the block results.
  def cartesian_product(*others) # :yields: tuple
    case
    when empty?
      self
    when others.empty?
      block_given? ? map(&Proc.new) : map
    else
      product = others[1..-1].inject(product(others[0])) do |intermediate, list| 
        intermediate.product(list) do |existing, new_element|
          existing + [ new_element ]
        end
      end
      if block_given?
        block = Proc.new
        product.map { |tuple| block[*tuple] }
      else
        product
      end
    end
  end

  # This module contains methods that are included into Ruby's Kernel module.
  module ObjectMethods
    # A method to improve the user friendliness for creating new lazy lists, that
    # cannot be described well with LazyList.iterate or LazyList.tabulate.
    #
    # - list without any arguments, returns the empty lazy list LazyList::Empty.
    # - list { x / y } returns a LazyList::ListBuilder object for a list
    #   comprehension, that can be transformed into a LazyList by calling the
    #   LazyList::ListBuilder#where method.
    # - list(x) returns the lazy list with only the element x as a member,
    #   list(x,y) returns the lazy list with only the elements x and y as a
    #   members, and so on.
    # - list(x) { xs } returns the lazy list with the element x as a head
    #   element, and that is continued with the lazy list xs as tail. To define an
    #   infinite lazy list of 1s you can do:
    #    ones = list(1) { ones } # => [1,... ]
    #   To define all even numbers directly, you can do:
    #    def even(n = 0) list(n) { even(n + 2) } end
    #   and then:
    #    e = even # => [0,... ]
    def list(*values, &block)
      values_empty = values.empty?
      result = LazyList[values]
      if block_given?
        if values_empty
          result = LazyList::ListBuilder.create_comprehend(&block)
        else
          result.instance_eval do
            ref(values.size - 1)
          end.instance_variable_set(:@tail, LazyList.delay(&block))
        end
      end
      result
    end

    # This method returns a Lazylist::ListBuilder instance for tuplewise building
    # of lists like the zip method does. This method call
    #
    #  build { x + y }.where(:x => 1..3, :y => 1..3)
    #
    # returns the same list [ 2, 4, 6 ] as this expression does
    #
    #  LazyList[1..3].zip(LazyList[1..3]) { |x, y| x + y }
    def build(&block)
      LazyList::ListBuilder.create_build(&block)
    end
  end

  class ::Object
    unless const_defined? :Infinity
      Infinity = 1 / 0.0
    end

    include LazyList::ObjectMethods
    include LazyList::Enumerable::ObjectMethods
  end
end
