class LazyList
  module Enumerable
    include ::Enumerable

    # Returns two lazy lists, the first containing the elements of this lazy
    # list for which the block evaluates to true, the second containing the
    # rest.
    def partition(&block)
      return select(&block), reject(&block)
    end

    # Returns a sorted version of this lazy list. This method should only be
    # called on finite lazy lists or it will never return. Also see
    # Enumerable#sort.
    def sort # :yields: a, b
      LazyList.from_enum(super)
    end

    # Returns a sorted version of this lazy list. This method should only be
    # called on finite lazy lists or it will never return. Also see
    # Enumerable#sort_by.
    def sort_by # :yields: obj
      LazyList.from_enum(super)
    end

    # Calls _block_ with two arguments, the element and its index, for each
    # element of this lazy list. If _block_ isn't given, the method returns a
    # lazy list that consists of [ element, index ] pairs instead.
    def each_with_index(&block)
      if block
        each_with_index.each { |x| block[x] }
      else
        i = -1
        map { |x| [ x, i += 1 ] }
      end
    end

    # Returns the lazy list, that contains all the given _block_'s return
    # values, if it was called on every
    #  self[i], others[0][i], others[1][i],... others[others.size - 1][i]
    # for i in 0..Infinity. If _block_ wasn't given
    # this result will be the array
    #  [self[i], others[0][i], others[1][i],... ]
    # and a lazy list of those arrays is returned.
    def zip(*others, &block)
      if empty? or others.any? { |o| o.empty? }
        empty
      else
        block ||= Tuple
        self.class.new(delay { block[head, *others.map { |o| o.head }] }) do
          tail.zip(*others.map { |o| o.tail }, &block)
        end
      end
    end

    # obsoleted by #zip
    def combine(other, &operator)
      warn "method 'combine' is obsolete - use 'zip'"
      zip(other, &operator)
    end

    # Returns a lazy list every element of this lazy list for which
    # pattern ===  element is true. If the optional _block_ is supplied,
    # each matching element is passed to it, and the block's result becomes
    # an element of the returned lazy list.
    def grep(pattern, &block)
      result = select { |x| pattern === x }
      block and result = result.map(&block)
      result
    end

    # Returns a lazy list of all elements of this lazy list for which the block
    # is false (see also +Lazylist#select+).
    def reject
      select { |obj| !yield(obj) }
    end

    # Returns a lazy list of all elements of this lazy list for which _block_
    # is true.
    def select(&block)
      block = All unless block
      s = self
      ended = catch(:end_list) do
        until s.empty? or block[s.head]
          s = s.tail
        end
      end
      if s.empty? or ended == :end_list
        empty
      else
        self.class.new(delay { s.head }) { s.tail.select(&block) }
      end
    end
    alias find_all select

    # obsoleted by #select
    def filter(&p)
      warn "method 'filter' is obsolete - use 'select'"
      select(&p)
    end

    # Creates a new Lazylist that maps the block or Proc object f to every
    # element in the old list.
    def map(&f)
      return empty if empty?
      f = Identity unless f
      self.class.new(delay { f[head] }) { tail.map(&f) }
    end
    alias collect map

    # obsoleted by #map
    def mapper(&f)
      warn "method 'mapper' is obsolete - use 'map'"
      map(&f)
    end

    module ObjectMethods
      # This method can be used to end a list in a predicate that is used to
      # filter the lazy list via the select, reject, or partition method.
      def end_list
        throw :end_list, :end_list
      end
    end
  end
end
