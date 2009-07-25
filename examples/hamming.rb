require 'lazylist'

# Computes the hamming sequence: that is the sequence of natural numbers, whose
# prime divisors are all <= 5.
hamming = list(1) do
  hamming.map { |x| 2 * x }.merge(
    hamming.map { |x| 3 * x }.merge(
      hamming.map { |x| 5 * x }))
end

max = (ARGV.shift || 100).to_i
hamming.each(max) do |x|
  print x, " "
  STDOUT.flush
end
puts
print hamming[1000], ", ", hamming[1001], "\n"
