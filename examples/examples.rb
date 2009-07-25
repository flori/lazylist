require 'lazylist'
$:.unshift 'examples'
require 'pi'

puts "Random number lazy list (infinite)"
def rand(s = 666)
  current = ((s * 1103515245 + 12345) / 65536) % 32768 
  list(current) { rand(current) }
end
r = rand(666)
r.each(10) { |x| print x, " " } ; puts
dice = r.map { |x| 1 + x % 6 }
dice.each(10) { |x| print x, " " } ; puts
coin = r.map { |x| x % 2 == 0 ? :head : :tail }
coin.each(10) { |x| print x, " " } ; puts

puts "Prime number lazy list with select (10000..1000000)"
prime = LazyList[10000..1000000].select do |x|
  not (2..Math.sqrt(x).to_i).find { |d| x % d == 0 }
end
prime.each(10) { |x| print x, " " } ; puts
p prime[1]
puts

puts "Squared prime numbers with map"
prime.map { |x| x ** 2 }.each(5) { |x| print x, " " } ; puts
puts

puts "Lazy Lists from mathematical sequences"
a196 = LazyList.iterate(35) { |x| x + x.to_s.reverse.to_i }
a196.each(10) { |x| print x, " " } ; puts
hailstone = LazyList.iterate(7) { |x| x % 2 == 0 ? x / 2 : 3 * x + 1 }
hailstone.each(20) { |x| print x, " " } ; puts
terras = LazyList.iterate(7) { |x| x % 2 == 0 ? x / 2 : (3 * x + 1) / 2 }
terras.each(20) { |x| print x, " " } ; puts
wolfram = LazyList.iterate(1) do |x|
  ((3.0 / 2) * (x % 2 == 0 ? x : x + 1)).to_i
end
wolfram.each(15) { |x| print x, " " } ; puts
puts

puts "Fibonacci lazy list with recursion"
fib = LazyList.tabulate(0) { |x| x < 2 ? 1 : fib[x-2] + fib[x-1] }
fib.each(10) { |x| print x, " " } ; puts
p fib[100]
puts

fib = nil
puts "Fibonacci lazy list with zip"
fib = list(1, 1) { fib.zip(fib.drop) { |a, b| a + b } }
fib.each(10) { |x| print x, " " } ; puts
p fib[100]
puts

fib = nil
puts "Fibonacci lazy list with a list and a build call"
fib = list(1, 1) { build { a + b }.where(:a => fib, :b => fib.drop) }
fib.each(10) { |x| print x, " " } ; puts
p fib[100]
puts

puts "Sum up odd numbers lazylist to get a squares stream"
odd = LazyList[1..Infinity].select { |x| x % 2 == 1 }
puts odd
squares = LazyList.tabulate(0) do |x|
  (0..x).inject(0) { |s, i| s + odd[i] }
end
puts squares
squares.each(10) { |x| print x, " " } ; puts
puts squares
puts odd
puts

puts "Lazy lists from io objects"
me = LazyList.io(File.new($0)) { |io| io.readline }
me.each(6) { |line| puts line }
p me[60]
puts me.length
puts

me = LazyList[File.new($0)]
me.each(6) { |line| puts line }
p me[66]
puts me.length
puts


p PI.take(10)

def window(l, n, m = 0)
  list([ l.take(n) * '', m ]) { window(l.drop, n, m + 1) }
end

w = window(PI, 6)
index = w.find { |(x, i)| x == '999999' and break i }
puts "Found Feynman point #{PI.take_span(index, 6)} at #{index}!"

puts "Proof that PI is the number of the beast"
w = window(PI, 3)
index = w.find { |(x, i)| x == '666' and break i }
puts "Found #{PI.take_span(index, 3)} at #{index}!"
