#!/usr/bin/env ruby

require 'test/unit'
require 'lazylist'

class TC_LazyEnumerable < Test::Unit::TestCase
  def setup
    @a = LazyList[%w[abc cdef aab efgh eefgh hijkl]]
    @o = list(1) { @o }
    @n = LazyList.from(1)
    @l = LazyList[1..5]
    @m = LazyList[5..8]
    @r = [5, -2, 3, 13, 0]
    @s = LazyList[@r]
  end

  def test_zip
    l = @l.zip @m
    assert_kind_of LazyList, l
    assert_equal [[1, 5], [2, 6], [3, 7], [4, 8]], l.to_a
  end

  def test_zip_and_block
    l = @l.zip(@m) { |x,y| x + y }
    assert_kind_of LazyList, l
    assert_equal [6, 8, 10, 12], l.to_a
    zipped = @n.zip(@o) { |x, y| x + y }
    assert_kind_of LazyList, zipped
    assert_equal (12..21).to_a, zipped[10,10].to_a
    assert_equal (2..11).to_a, zipped[0,10].to_a
  end

  def test_zip_multiple_and_block
    zipped = @n.zip(@o, @m) { |x, y, z| x * z + y }
    assert_kind_of LazyList, zipped
    assert_equal [6, 13, 22, 33], zipped.to_a
  end

  def test_each_with_index
    l = @m.each_with_index
    assert_kind_of LazyList, l
    assert_equal l.to_a, [ [5, 0], [6, 1], [7, 2], [8, 3] ]
  end

  def test_each_with_index_and_block
    @m.each_with_index { |x, i| assert_equal x - 5, i }
  end

  def test_sort
    l = @s.sort
    assert_kind_of LazyList, l
    assert @r.sort, l
  end

  def test_sort_by
    l = @s.sort_by { |x| -x }
    assert_kind_of LazyList, l
    assert @r.sort_by { |x| -x }, l
  end

  def test_grep
    l = @a.grep /e/
    assert_kind_of LazyList, l
    assert_equal %w[cdef efgh eefgh], l.to_a
  end

  def test_grep_with_block
    expected = %w[cdef efgh eefgh]
    i = 0 
    l = @a.grep(/e/) do |x|
      assert_equal expected[i], x
    end
  end

  def test_reject
    odd = @n.select { |x| x % 2 == 1 }
    assert_kind_of LazyList, odd
    assert_equal [1, 3, 5, 7, 9], odd.take(5)
  end

  def test_reject
    odd = @n.reject { |x| x % 2 == 0 }
    assert_kind_of LazyList, odd
    assert_equal [1, 3, 5, 7, 9], odd.take(5)
  end

  def test_partition
    even, odd = @l.partition { |x| x % 2 == 0 }
    assert_kind_of LazyList, odd
    assert_kind_of LazyList, even
    assert_equal [2, 4], even.take(5)
    assert_equal [1, 3, 5], odd.take(5)
  end

  def test_select
    fib = list(1, 1) { build { a + b }.where(:a => fib, :b => fib.drop(1)) }
    fib_small = fib.select { |x| x <= 4_000_000 or end_list }
    even_fib_small = fib_small.select { |x| x % 2 == 0 }
    assert_equal [ 1, 1, 2, 3, 5, 8, 13, 21, 34, 55 ], fib_small.first(10)
    assert_equal [ 2, 8, 34, 144, 610, 2584, 10946, 46368, 196418, 832040 ], even_fib_small.first(10)
    assert_equal [ 2, 8, 34, 144, 610, 2584, 10946, 46368, 196418, 832040, 3524578 ], even_fib_small.first(11)
    assert_equal [ 2, 8, 34, 144, 610, 2584, 10946, 46368, 196418, 832040, 3524578 ], even_fib_small.first(12)
  end
end
