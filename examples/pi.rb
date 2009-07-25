require 'lazylist'

# This spigot algorithm computes an unbounded number of digits of Pi and
# uses a lazy list to save them.
#
# References:
# - Jeremy Gibbons (2003). An Unbounded Spigot Algorithm for the Digits of Pi.
#   http://web.comlab.ox.ac.uk/oucl/work/jeremy.gibbons/publications/spigot.pdf
#

def f(q,r,t, k)
  n = (3 * q + r) / t
  if n == (4 * q + r) / t
    list(n) { f(10 * q, 10 * (r - n * t), t, k) }
  else
    f(q * k, q * (4 * k + 2) + r * (2 * k + 1), t * (2 * k + 1), k + 1)
  end
end

PI = f(1, 0, 1, 1)  # Setup my lazy list

if $0 == __FILE__
  max = ARGV.empty? ? nil : ARGV.shift.to_i
  sum = PI[0, 1000].inject(0) do |s, i| s += i end
  puts "Sum of the first 1000 digitis of pi: #{sum}"
  puts "500th digit using memoized computation: #{PI[499]}"

  puts "Printing #{max ? "the first #{max}" : "all the "} digits of pi:" # vim-uff: "
  PI.each!(max) do |x|
    STDOUT.print x
    STDOUT.flush
  end
  puts
end
