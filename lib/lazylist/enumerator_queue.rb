class LazyList
  # ReadQueue is the implementation of an read-only queue that only supports
  # #shift and #empty? methods.  It's used as a wrapper to encapsulate
  # enumerables in lazy lists.
  class ReadQueue
    # Creates an ReadQueue object from an enumerable.
    def initialize(enumerable)
      @enum = enumerable.to_enum
      @empty = false
      shift
    end

    # Extracts the top element from the queue or nil if the queue is empty.
    def shift
      if @empty
        nil
      else
        result = @next
        @next = @enum.next
        result
      end
    rescue StopIteration
      @next = nil
      @empty = true
      result
    end

    alias pop shift # for backwards compatibility

    # Returns true if the queue is empty.
    def empty?
      !@next and @empty
    end
  end
end
