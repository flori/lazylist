#!/usr/bin/env ruby

require 'test/unit'
require 'lazylist'
require 'tempfile'

class MyEnum
  include Enumerable

  def initialize(n)
    @n = n
  end

  def each(&block)
    (1..@n).each(&block)
  end
end

class TC_LazyList < Test::Unit::TestCase
  Empty = LazyList::Empty

  def setup
    @strings = LazyList.tabulate("a")
    @natural = LazyList.tabulate(1)
    @ones = LazyList.iterate(1) { 1 }
    @oddp = lambda { |x| x % 2 == 1 }
    @odd = @natural.select(&@oddp)
    @evenp = lambda { |x| x % 2 == 0 }
    @boolean = @natural.map { |x| x % 2 == 0}
    @even = @natural.select(&@evenp)
    @finite_inner0 = MyEnum.new(0)
    @finite0 = LazyList[@finite_inner0]
    @finite_inner1 = MyEnum.new(1)
    @finite1 = LazyList[@finite_inner1]
    @finite_inner10 = MyEnum.new(10)
    @finite10 = LazyList[@finite_inner10]
    @finite_span = LazyList.span("A", 10)
    @finite_span_generated = ("A".."J").to_a
  end

  def test_constructor
    ll1 = LazyList.new(:foo, Empty)
    assert(!ll1.empty?)
    ll2 = LazyList.new(:foo) { Empty }
    assert(!ll2.empty?)
    assert_raises(LazyList::Exception) do
       ll3 = LazyList.new(:foo, :argh) { Empty }
    end
  end

  def test_read_queue
    @read_queue0 = LazyList::ReadQueue.new(1..0)
    @read_queue1 = LazyList::ReadQueue.new(1..1)
    @read_queue10 = LazyList::ReadQueue.new(1..10)
    assert(@read_queue0.empty?)
    assert_equal nil, @read_queue0.pop
    assert(!@read_queue1.empty?)
    assert_equal 1, @read_queue1.pop
    assert(!@read_queue10.empty?)
    for i in 1..10 do
      assert_equal i, @read_queue10.pop
    end
  end

  def test_finite
    assert_equal @finite_inner0.to_a, @finite0.to_a
    assert_equal @finite_inner1.to_a, @finite1.to_a
    assert_equal @finite_inner10.to_a, @finite10.to_a
    assert_equal @finite_span_generated, @finite_span.to_a
    assert_equal @finite_span_generated, LazyList["A"..."K"].to_a
  end

  def test_size
    assert_equal 0, @finite0.size
    assert_equal 1, @finite1.size
    assert_equal 10, @finite10.size
    assert_equal 10, @finite_span.size
    assert_equal 0, @finite0.length
    assert_equal 1, @finite1.length
    assert_equal 10, @finite10.length
    assert_equal 10, @finite_span.length
  end

  def test_select
    assert_equal 1, @odd[0]
    assert_equal 3, @odd[1]
    assert_equal 5, @odd[2]
    assert_equal [3, 5, 7], @odd.take_range(1..3)
    assert_equal [3, 5, 7, 9], @odd.take_span(1, 4)
    assert_equal((1..19).select(&@oddp), @odd[0, 10].to_a)
    assert_equal((1..10).to_a, @natural[0, 10].to_a)
    assert_equal [ 1 ] * 10, @ones[0, 10].to_a
    ends_with_a = @strings.select { |x| x[-1] == ?a }
    assert_equal ends_with_a[0, 27].to_a,
      [ "a", ("a".."z").map { |x| x + "a" }  ].flatten
  end

  def test_map
    id = @natural.map
    assert_equal 1, id[0]
    assert_equal 2, id[1]
    assert_equal 3, id[2]
    assert_equal((1..10).to_a, id[0, 10].to_a)
    assert_equal((1..10).to_a, @natural[0, 10].to_a)
    squaredf = lambda { |x| x ** 2 }
    squared = @natural.map(&squaredf)
    assert_equal 1, squared[0]
    assert_equal 4, squared[1]
    assert_equal 9, squared[2]
    assert_equal((1..10).map(&squaredf), squared[0, 10].to_a)
    assert_equal((1..10).to_a, @natural[0, 10].to_a)
    strangef = lambda { |x| x * (x.unpack('c').first - 'a'.unpack('c').first + 1) }
    strange = @strings.map(&strangef)
    assert_equal "a", strange[0]
    assert_equal "bb", strange[1]
    assert_equal "ccc", strange[2]
    assert_equal(("a".."z").map(&strangef), strange[0, 26].to_a)
    assert_equal(("a".."z").to_a, @strings[0, 26].to_a)
  end

  def test_index
    assert_equal nil, Empty[-1]
    assert_equal nil, Empty[0]
    assert_equal nil, Empty[1]
    assert @natural.cached?
    assert_equal nil, @natural[-1]
    assert_equal nil, @natural[-1]
    assert_equal 1, @natural[0]
    assert_equal 1, @natural[0]
    assert_equal 2, @natural[1]
    assert_equal 2, @natural[1]
    assert_equal nil, @natural[-1, 10]
    assert_equal((1..10).to_a, @natural[0, 10].to_a)
    assert_equal((6..15).to_a, @natural[5, 10].to_a)
    assert_equal((1..1).to_a, @natural[0..0].to_a)
    assert_equal((1..0).to_a, @natural[0..-1].to_a)
    assert_equal((1...1).to_a, @natural[0...0].to_a)
    assert_equal((1...0).to_a, @natural[0...-1].to_a)
    assert_equal((1..10).to_a, @natural[0..9].to_a)
    assert_equal((6..15).to_a, @natural[5..14].to_a)
    assert_equal((1..10).to_a, @natural[0...10].to_a)
    assert_equal((6..15).to_a, @natural[5...15].to_a)
  end

  def test_index_without_cache
    Empty.cached = false
    assert_equal nil, Empty[-1]
    assert_equal nil, Empty[0]
    assert_equal nil, Empty[1]
    @natural.cached = false
    assert !@natural.cached?
    assert_equal nil, @natural[-1]
    assert_equal nil, @natural[-1]
    assert_equal 1, @natural[0]
    assert_equal 1, @natural[0]
    assert_equal 2, @natural[1]
    assert_equal 2, @natural[1]
    assert_equal nil, @natural[-1, 10]
  end

  def test_merge
    natural = @even.merge(@odd)
    assert_equal @natural[0, 10].to_a, natural[0, 10].to_a
    natural = @odd.merge(@even)
    assert_equal @natural[0, 10].to_a, natural[0, 10].to_a
    double_list = @natural.merge(@natural) { |a,b| a <= b }
    assert double_list[0, 10].to_a, (1..5).map { |x| [x, x] }.flatten
    odd2 = @natural.select(&@oddp).drop(1)
    some = @even.merge(odd2)
    assert_equal @natural[1, 9].to_a, some[0, 9].to_a
    more_ones = @ones.merge(@ones)
    assert_equal [1] * 10, more_ones.take(10)
  end

  def test_take_drop
    assert_equal [ ], @odd.take(0)
    assert_equal [ 1, 3, 5 ], @odd.take(3)
    assert_equal [ 1, 3, 5 ], @odd.take(3)
    assert_equal [ ], @odd.take!(0)
    assert_equal [ 1 ], @odd.take(1)
    assert_equal [ 1 ], @odd.take!(1)
    assert_equal [ 3, 5, 7 ], @odd.take(3)
    assert_equal [ 3, 5 ], @odd.take!(2)
    assert_equal [ 7, 9, 11 ], @odd.take(3)
    assert_equal [ 7, 9, 11 ], @odd.drop(0).take(3)
    assert_equal [ 7, 9, 11 ], @odd.take(3)
    assert_equal [ 9, 11, 13 ], @odd.drop(1).take(3)
    assert_equal [ 7, 9, 11 ], @odd.take(3)
    assert_equal [ 11, 13, 15 ], @odd.drop(2).take(3)
    assert_equal [ 7, 9, 11 ], @odd.take(3)
    @odd.drop!(0)
    assert_equal [ 7, 9, 11 ], @odd.take(3)
    @odd.drop!(1)
    assert_equal [ 9, 11, 13 ], @odd.take(3)
    @odd.drop!(2)
    assert_equal [ 13, 15, 17 ], @odd.take(3)
    assert_equal [ 13, 15, 17 ], @odd.first(3)
    assert_equal [ 8, 9, 10 ], @finite10.last(3)
  end

  def test_io
    @tempfile0 = Tempfile.new("test")
    1.upto(0) do |i|
      @tempfile0.puts i
    end
    @tempfile0.close
    @tempfile0_list = LazyList[File.new(@tempfile0.path)]
    @tempfile10 = Tempfile.new("test")
    1.upto(10) do |i|
      @tempfile10.puts i
    end
    @tempfile10.close
    @tempfile10_list = LazyList[File.new(@tempfile10.path)]
    assert_equal 0, @tempfile0_list.size
    assert_equal [], @tempfile0_list.to_a
    assert_equal 10, @tempfile10_list.size
    assert_equal((1..10).map { |x| x.to_s + "\n" }, @tempfile10_list.to_a)
    temp = LazyList.io(File.new(@tempfile0.path)) do |io|
      io.readline
    end
    content = temp.inject([]) { |c, line| c << line }
    assert_equal [], content
    temp = LazyList.io(File.new(@tempfile10.path)) do |io|
      io.readline
    end
    content = temp.inject([]) { |c, line| c << line }
    assert_equal((1..10).map { |x| x.to_s + "\n" }, content)
  end

  def test_construct_ref
    assert_equal Empty, LazyList[0, -1]
    assert_equal [0], LazyList[0, 1].to_a
    assert_equal((0..9).to_a, LazyList[0, 10].to_a)
    assert_equal Empty, LazyList[0..-1]
    assert_equal [0], LazyList[0..0].to_a
    assert_equal((0..9).to_a, LazyList[0..9].to_a)
  end

  def test_iterate
    f = LazyList.iterate(5) do |x|
      if x % 2 == 0
        x / 2
      else
        5 * x + 1
      end
    end
    assert_equal nil, f[-1]
    assert_equal 5, f[0]
    assert_equal 26, f[1]
    assert_equal [5, 26, 13, 66, 33, 166, 83, 416], f[0, 8].to_a
    a196 = LazyList.iterate(35) { |x| x + x.to_s.reverse.to_i }
    assert_equal [35, 88, 176, 847, 1595, 7546, 14003, 44044, 88088, 176176],
      a196.take(10)
  end

  def test_inspect
    l = LazyList[1..11]
    assert_equal "[]", Empty.inspect
    assert_equal "[... ]", l.inspect
    l[0]
    assert_equal "[1,... ]", l.inspect
    l[1]
    assert_equal "[1, 2,... ]", l.inspect
    l[2]
    assert_equal "[1, 2, 3,... ]", l.inspect
    l[9]
    assert_equal "[1, 2, 3, 4, 5, 6, 7, 8, 9, 10,... ]", l.inspect
    l.to_a
    assert_equal "[1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11]", l.inspect
  end

  def test_zip
    combined = @natural.zip(@ones) { |x, y| x + y }
    assert_equal((12..21).to_a, combined[10,10].to_a)
    assert_equal((2..11).to_a, combined[0,10].to_a)
  end

  def from(n = 0)
    list(n) { from(n + 1) }
  end

  def odd
    from(1).select { |x| x % 2 == 1 }
  end

  def test_list
    assert_equal Empty, list
    assert_equal [], list.to_a
    assert_equal LazyList.new(1) { Empty }, list(1)
    assert_equal [1], list(1).to_a
    assert_equal Empty, list
    o = odd
    assert_equal [1, 3, 5, 7, 9, 11, 13, 15, 17, 19], o.take(10)
    assert_equal @odd.take(10), o.take(10)
    ones = list(1) { ones }
    assert_equal '[... ]', ones.inspect
    assert_equal 1, ones.head
    assert_equal '[1,... ]', ones.inspect
    assert_equal [ 1 ] * 10 , ones.take(10)
    assert_equal '[1,... ]', ones.inspect
    assert_equal [:foo], LazyList[:foo].to_a
  end

  def test_sublist
    assert_equal Empty, @natural.sublist(-1)
    assert_equal Empty, @natural.sublist(0)
    assert_equal [1], @natural.sublist(1).to_a
    assert_equal((1..10).to_a, @natural.sublist(10).to_a)
    assert_equal((6..15).to_a, @natural[5, 10].to_a)
    assert_equal((6..15).to_a, @natural[5..14].to_a)
    assert_equal((6..14).to_a, @natural[5...14].to_a)
    assert_equal nil, @natural.sublist(10)[10]
    assert_equal 10, @natural.sublist(10)[9]
  end

  def test_append
    l1 = LazyList[1..3]
    l2 = LazyList[5..7]
    l3 = @natural.drop(8)
    assert_equal [], Empty.append.to_a
    assert_equal [], Empty.append(Empty).to_a
    assert_equal [], (Empty + Empty).to_a
    assert_equal [], Empty.append(Empty, Empty).to_a
    assert_equal [1, 2, 3], Empty.append(Empty, l1).to_a
    assert_equal [1, 2, 3], Empty.append(l1, Empty).to_a
    assert_equal [1, 2, 3], Empty.append(Empty, l1, Empty).to_a
    assert_equal [5, 6, 7, 1, 2, 3], l2.append(Empty, l1, Empty).to_a
    assert_equal [1, 2, 3], l1.append.to_a
    assert_equal [1, 2, 3], (l1 + Empty).to_a
    assert_equal [1, 2, 3], (Empty + l1).to_a
    assert_equal [1, 2, 3, 5, 6, 7], l1.append(l2).to_a
    assert_equal [1, 2, 3, 5, 6, 7], (l1 + l2).to_a
    assert_equal [1, 2, 3], l1.append(Empty).to_a
    assert_equal [1, 2, 3], Empty.append(l1).to_a
    assert_equal [1, 2, 3] + [5, 6, 7] + [9, 10, 11, 12],
      l1.append(l2, l3).take(10)
  end

  def test_list_builder
    lb = build { y * x }
    assert_kind_of LazyList::ListBuilder, lb
    assert_equal "#<LazyList::ListBuilder>", lb.to_s
    l = lb.where :x => 1..10, :y => 'a'..'j' do
      x % 2 == 0 && y < 'j'
    end
    assert_kind_of LazyList, l
    assert_equal ["bb", "dddd", "ffffff", "hhhhhhhh"], l.to_a
    l = build { y * x }.where :x => 1..10, :y => 'a'..'j'
    assert_equal ["a", "bb", "ccc", "dddd", "eeeee", "ffffff", "ggggggg",
      "hhhhhhhh", "iiiiiiiii", "jjjjjjjjjj"], l.to_a
  end

  def twice(x)
    2 * x
  end

  def test_list_comprehend
    f = LazyList[1..3]
    g = LazyList[1..2]
    assert_equal [ ], LazyList.mix(LazyList::Empty).to_a
    assert_equal [ ], LazyList.mix(LazyList::Empty, LazyList::Empty).to_a
    assert_equal [ 1 ], LazyList.mix(list(1), LazyList::Empty).to_a
    assert_equal [ 1 ], LazyList.mix(LazyList::Empty, list(1)).to_a
    assert_equal [ 1, 1, 2, 2, 3 ], LazyList.mix(f, g).to_a
    assert_equal list, list * list
    assert_equal list, list * list(1)
    assert_equal list, list(1) * list
    assert_equal list, list.cartesian_product
    assert_equal [ [1, 1], [1, 2], [2, 1], [2, 2], [3, 1], [3, 2] ],
      f.cartesian_product(g).to_a
    assert_equal [[1, 1, 1], [1, 1, 2], [1, 2, 1], [1, 2, 2], [2, 1, 1], [2, 1,
      2], [2, 2, 1], [2, 2, 2]], g.cartesian_product(g, g).to_a
    assert_equal [1, 2, 2, 4, 2, 4, 4, 8],
      g.cartesian_product(g, g, &lambda { |x,y,z| x * y * z }).to_a
    assert_equal g.map { |x| x * x }, g.cartesian_product { |x| x * x }
    l = list { [ x, y ] }.where :x => g, :y => g
    assert_equal [ [ 1, 1 ], [ 1, 2 ], [ 2, 1 ], [ 2, 2 ] ], l.to_a.sort
    l = list { [ x, y ] }.where :x => f, :y => g
    assert_equal [ [ 1, 1 ], [ 1, 2 ], [ 2, 1 ], [ 2, 2 ], [ 3, 1 ], [ 3, 2 ] ], l.to_a.sort
    l = list { [ x, y ] }.where(:x => f, :y => f) {  x > y }
    assert_equal [ [ 2, 1 ], [ 3, 1 ], [ 3, 2 ] ], l.to_a.sort
    l = list { [ x, y ] }.where(:x => f, :y => f) {  x <= y }
    assert_equal [ [1, 1], [1, 2], [1, 3], [2, 2], [2, 3], [3, 3] ], l.to_a.sort
    test = list { x * y }.where :x => 1..4, :y => list(3, 5, 7, 9)
    assert_equal [ 3, 5, 6, 7, 10, 14, 9, 9, 21, 27, 15, 18, 36, 12, 28, 20 ].sort, test.to_a.sort
    test = list { x + twice(y) }.where :x => 1..4, :y => list(3, 5, 7, 9)
    assert_equal [ 7, 11, 8, 15, 12, 16, 9, 19, 17, 21, 13, 20, 22, 10, 18, 14 ].sort, test.to_a.sort
  end
end
