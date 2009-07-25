class LazyList
  # ReadQueue is the implementation of an read-only queue that only supports
  # #shift and #empty? methods.  It's used as a wrapper to encapsulate
  # enumerables in lazy lists.
  class ReadQueue
    # Creates an ReadQueue object from an enumerable.
    def initialize(enumerable)
      @data = []
      @producer = Thread.new do
        Thread.stop
        begin
          enumerable.each do |value|
            old, Thread.critical = Thread.critical, true
            begin
              @data << value
              @consumer.wakeup
              Thread.stop
            ensure
              Thread.critical = old
            end
          end
        rescue => e
          @consumer.raise e
        ensure
          @consumer.wakeup
        end
      end
      Thread.pass until @producer.stop?
    end

    # Extracts the top element from the queue or nil if the queue is
    # empty.
    def shift
      if empty?
        nil
      else
        @data.shift
      end
    end

    alias pop shift # for backwards compatibility

    # Returns true if the queue is empty.
    def empty?
      if @data.empty?
        old, Thread.critical = Thread.critical, true
        begin
          @consumer = Thread.current
          @producer.wakeup
          Thread.stop
        rescue ThreadError
          ;
        ensure
          @consumer = nil
          Thread.critical = old
        end
      end
      @data.empty?
    end
  end
end
