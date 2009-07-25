require 'lazylist'

# Sieve or Eratosthenes with filters on Lazy Lists. It has a very nice
# notation, but is a real memory and cpu hog. Enjoy!
def primes(l = LazyList.from(2))
  current, rest = l.head, l.tail
  list(current) do
    primes rest.select { |x| (x % current) != 0 }
  end
end

max = (ARGV.shift || 100).to_i
primes.each(max) do |x|
  print x, " "
  STDOUT.flush
end
puts
