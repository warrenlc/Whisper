# Authors: Viktor Norlin & Warren Crutcher

require_relative "../whisper/whisper.rb"
require "test/unit"


class Test_Literals < Test::Unit::TestCase
    def test_integer
        w = Whisper.new
        
        assert_equal(1.0, w.get_parser_string("1"))
        assert_equal(0.0, w.get_parser_string("0"))
    end

    def test_double
        w = Whisper.new
        
        assert_equal(5.5, w.get_parser_string("5.5"))
        assert_equal(0.0, w.get_parser_string("0.0"))
    end

    def test_boolean
        w = Whisper.new
        
        assert_equal(false, w.get_parser_string("false"))
        assert_equal(true, w.get_parser_string("true"))
    end
    
    def test_parenthesis_literal 
        w = Whisper.new

        assert_equal(77, w.get_parser_string("(77)"))
        assert_equal(true, w.get_parser_string("(true)"))
    end
end

class Test_Arithmetics < Test::Unit::TestCase
    def test_addition
        w = Whisper.new

        assert_equal(2, w.get_parser_string("1+1"))
        assert_equal(2, w.get_parser_string("1+1"))
        assert_equal(2, w.get_parser_string("1 + 1"))
        assert_equal(2, w.get_parser_string("1+1.0"))
        assert_equal(3.5, w.get_parser_string("1+2.5"))
        assert_equal(4.0, w.get_parser_string("2.0+2.0"))
    end

    def test_unary_minus
        w = Whisper.new
        assert_equal(-29.0, w.get_parser_string("-((((2@3)-4)*5)+((6/2)*3))"))
        assert_equal(-938.0, w.get_parser_string("-(((((2@3)*3)+4)*5)-6)*7"))
        assert_equal(-9.5, w.get_parser_string("-((((((2+3)*4)-5)/6)*7)-8)"))
        assert_equal(0, w.get_parser_string("0"))
    end

    def test_subtraction
        w = Whisper.new

        assert_equal(1.0, w.get_parser_string("3-2"))
        assert_equal(1.0, w.get_parser_string("3 - 2"))
        assert_equal(2.0, w.get_parser_string("3-1.0"))
        assert_equal(1.5, w.get_parser_string("3-1.5"))
        assert_equal(0.0, w.get_parser_string("2.0-2.0"))
    end

    def test_multiplication
        w = Whisper.new

        assert_equal(10.0, w.get_parser_string("5*2"))
        assert_equal(10.0, w.get_parser_string("5 * 2"))
        assert_equal(6.0, w.get_parser_string("3*2.0"))
        assert_equal(4.5, w.get_parser_string("3*1.5"))
        assert_equal(4.0, w.get_parser_string("2.0*2.0"))
    end

    def test_division
        w = Whisper.new

        assert_equal(2.5, w.get_parser_string("5/2"))
        assert_equal(2.5, w.get_parser_string("5 / 2"))
        assert_equal(1.5, w.get_parser_string("3/2.0"))
        assert_equal(2.0, w.get_parser_string("3/1.5"))
        assert_equal(1.0, w.get_parser_string("2.0/2.0"))
    end

    def test_exponentials
        w = Whisper.new

        assert_equal(25.0, w.get_parser_string("5@2"))
        assert_equal(25.0, w.get_parser_string("5 @ 2"))
        assert_equal(9.0, w.get_parser_string("3@2.0"))
        assert_equal(8.0, w.get_parser_string("4@1.5"))
        assert_equal(4.0, w.get_parser_string("2.0@2.0"))
    end

    def test_bitwise 
        w = Whisper.new

        assert_equal(130, w.get_parser_string("let a = 147; let b = a^17"))
        assert_equal(8, w.get_parser_string("let a = 16; let a = a >> 1"))
        assert_equal(4, w.get_parser_string("let a = 16; while a  != 4 do {let a = a >> 1}"))
        assert_equal(-141, w.get_parser_string("let a  = 140; let b = ~a"))
        assert_equal(1, w.get_parser_string("let a = 5; let b = 3; 5 & 3"))
        assert_equal(7, w.get_parser_string("5 | 3"))
        assert_equal(6, w.get_parser_string("5^3"))
        assert_equal(20, w.get_parser_string("5<<2"))
        assert_equal(2, w.get_parser_string("10 >> 2"))
        assert_equal(-6, w.get_parser_string("~5"))
    end

    def test_parenthesis
        w = Whisper.new

        assert_equal(770.0, w.get_parser_string("(7*11*10)"))
        assert_equal(60.0, w.get_parser_string("100 -(40)"))
        assert_equal(1.0, w.get_parser_string("(1+1+1+1+1+1+1) -6"))
    end

    def test_priority
        w = Whisper.new

        assert_equal(7.0, w.get_parser_string("1+2*3"))
        assert_equal(9.0, w.get_parser_string("(1+2)*3"))
        assert_equal(7.0, w.get_parser_string("1+(2*3)"))
        assert_equal(19.0, w.get_parser_string("1+(2*(3+6))"))
        assert_equal(29.0, w.get_parser_string("((((2@3)-4)*5)+((6/2)*3))"))
        assert_equal(938.0, w.get_parser_string("(((((2@3)*3)+4)*5)-6)*7"))
        assert_equal(9.5, w.get_parser_string("((((((2+3)*4)-5)/6)*7)-8)"))
    end
end

class TestLogic < Test::Unit::TestCase
    def test_or
        w = Whisper.new

        assert_equal(true, w.get_parser_string("true||false"))
        assert_equal(true, w.get_parser_string("true || false"))
        assert_equal(false, w.get_parser_string("false||false"))
        assert_equal(true, w.get_parser_string("true||true"))
        assert_equal(true, w.get_parser_string("false||true"))
    end

    def test_and
        w = Whisper.new

        assert_equal(false, w.get_parser_string("true&&false"))
        assert_equal(false, w.get_parser_string("true && false"))
        assert_equal(false, w.get_parser_string("false&&false"))
        assert_equal(true, w.get_parser_string("true&&true"))
        assert_equal(false, w.get_parser_string("false&&true"))
    end

    def test_not 
        w = Whisper.new
        
        assert_equal(false, w.get_parser_string("!true"))
        assert_equal(true, w.get_parser_string("!false"))
    end

    def test_parenthesis
        w = Whisper.new

        assert_equal(false, w.get_parser_string("(true&&false)"))
        assert_equal(false, w.get_parser_string("true&&(false)"))
        assert_equal(false, w.get_parser_string("(true)&& false"))
        assert_equal(true, w.get_parser_string("!(true&&false)"))
        assert_equal(false, w.get_parser_string("!true&&(false)"))
        assert_equal(false, w.get_parser_string("!(true)&& false"))
    end

    def test_priority
        w = Whisper.new

        assert_equal(true, w.get_parser_string("(!(!true || false) && !(false && true)) || (false || (false && !(true || false)))"))
        assert_equal(true, w.get_parser_string("!((true && !(false || true)) || !(false || (!false && true))) && true"))
        assert_equal(false, w.get_parser_string("(false || !(true && (false || !(false && true)))) && !(false && true || !false) "))
        assert_equal(false, w.get_parser_string("!(!(true && (false || !(true || false))) || !(false && true)) || true && false"))
        assert_equal(true, w.get_parser_string("((true || false) && !(false || (true && !(false || !false)))) || (!true && (false && true))"))
        assert_equal(true, w.get_parser_string("!(!(true || false) && (false || (!false || true))) && ((false && true) || !(false && true))"))
        assert_equal(false, w.get_parser_string("((false && true) || !(false || true)) && !(false && (true || !true) || !false) || !true"))
        assert_equal(false, w.get_parser_string("!((true && false) || !(false || (true && !(false || !false))) || !(false && true)) && false "))
        assert_equal(true, w.get_parser_string("((true || false) && !false) || !(false && (true || !(false || true)) && !(true && !false))"))

    end
end

class Test_Assignment < Test::Unit::TestCase
    def test_assign
        w = Whisper.new

        assert_equal(666.0, w.get_parser_string("let a = 666"))
        assert_equal(true, w.get_parser_string("let a = (!(!true || false) && !(false && true)) || (false || (false && !(true || false)))"))
        assert_equal(true, w.get_parser_string("let a = !((true && !(false || true)) || !(false || (!false && true))) && true"))
        assert_equal(false, w.get_parser_string("let a = (false || !(true && (false || !(false && true)))) && !(false && true || !false) "))
    
        assert_equal(7.0, w.get_parser_string("let a = 1+2*3"))
        assert_equal(9.0, w.get_parser_string("let a = (1+2)*3"))
        assert_equal(7.0, w.get_parser_string("let a = 1+(2*3)"))
        assert_equal(19.0, w.get_parser_string("let a=1+(2*(3+6))"))
        assert_equal(29.0, w.get_parser_string("let a= ((((2@3)-4)*5)+((6/2)*3))"))
        assert_equal(938.0, w.get_parser_string("let joED_iR_t_ = (((((2@3)*3)+4)*5)-6)*7"))
        assert_equal(9.5, w.get_parser_string("let f=((((((2+3)*4)-5)/6)*7)-8)"))
    end

end

class Test_IfNode < Test::Unit::TestCase
    
    def test_if
        w = Whisper.new
        assert_equal(7.0, w.get_parser_string("if true then {1+2*3}"))
        assert_equal(9.0, w.get_parser_string("if !false then { (1+2)*3 }"))
        assert_not_equal(7.0, w.get_parser_string("if 4 > 5 then {1+(2*3)}"))
        assert_equal(29.0, w.get_parser_string("if (2 < 6) then { ((((2@3)-4)*5)+((6/2)*3))}"))
        assert_equal(938.0, w.get_parser_string("if (true) then {(((((2@3)*3)+4)*5)-6)*7}"))
        assert_equal(1.0, w.get_parser_string("if !!!!!!!!true then {1}"))
    
        assert_not_equal(7.0, w.get_parser_string("if 4 > 5 then { 1+(2*3) }"))
        assert_not_equal(19.0, w.get_parser_string("if (4 != 4) then { 1+(2*(3+6)) }"))
    end

    def test_if_else 
        w = Whisper.new
        assert_equal(7.0, w.get_parser_string("if true then {1+2*3} else {1+1} "))
        assert_equal(9.0, w.get_parser_string("if !false then { (1+2)*3 } else { 17+31 }"))
        assert_equal(0.0, w.get_parser_string("if (4 != 4) then { 1+(2*(3+6)) } else {0}"))
        assert_equal(17.0, w.get_parser_string("if (2 > 6) then { ((((2@3)-4)*5)+((6/2)*3))} else { 17 }"))
        assert_equal(9.0, w.get_parser_string("if !(true) then {(((((2@3)*3)+4)*5)-6)*7} else { 9 }"))

        # TODO:
        # Test nested if and if-else statements
        assert_equal(10.0, w.get_parser_string("if true then { if !false then {10}}"))
        assert_equal(0.0, w.get_parser_string("if !true then {if true then {17} else {if true then {0}}} else {0}"))
        assert_equal(17.0, w.get_parser_string("if true then {if true then {17} else {if true then {0}}} else {0}"))
    end 
end

class Test_WhileNode < Test::Unit::TestCase
    def test_while
        w = Whisper.new
        # Test that while a < 0, we can operate on a
        assert_equal(10.0, w.get_parser_string("let a = 0; while a < 10 do {a+=1}; a"))
        # Test that nothing happens when condition is false
        assert_equal(0.0, w.get_parser_string("let a= 0; while a > 10 do {let a= a+1}; a"))
        # Test while-if combination
        assert_equal(10.0, w.get_parser_string("let a = 0; let b = 0; while a < 10 do {a+=1; let b = a}; a"))
        # Test nested while-loops
        assert_equal(5.0, w.get_parser_string("let a = 0; let b = 0; while a < 5 do { while b < 5 do {b+=1; a+=1}}; b"))
    end
end

class Test_Function < Test::Unit::TestCase
    def test_function_assignment
        w = Whisper.new

        # Make sure that all these functions parse correctly
        # and that the definition returns an object
        # of class Node_Function_Define
        assert_equal(Node_Function_Define, w.get_parser_string("let f(x) = {x}").class)
        assert_equal(Node_Function_Define, w.get_parser_string("let nice_func(x, y, z) = {z}").class)
        assert_equal(Node_Function_Define, w.get_parser_string("let _____yo_(a, _, b) = {_}").class)
        assert_equal(Node_Function_Define, w.get_parser_string("let many_arguments_dot_com(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s, t, u, v, x, y, z) = {a; b; c}").class)
        assert_equal(Node_Function_Define, w.get_parser_string("let reasonable_function_body(a, b) = {let c = a + b; if c > 5 then {a} else {b}}").class)
        assert_equal(Node_Function_Define, w.get_parser_string("let add_numbers_up_to(a, b) = {let c = a; let sum = 0; while c <= b do {let sum = sum + c; let c = c + 1}; sum}").class)
    end

    def test_function_call
        w = Whisper.new

        # Test a simple function
        assert_equal(69.0, w.get_parser_string("let f(x) = {x}; f(69)"))

        # Test a function that takes two variables as arguments instead of just plain numbers
        assert_equal(4.0, w.get_parser_string("let reasonable_function_body(a, b) = {let c = a + b; if c > 5 then {a} else {b}}; let a = 4; let b = 2; reasonable_function_body(a, b)"))

        # Test a function that takes two numbers,
        # and returns the sum of adding all numbers from number a to number b.
        # Uses a while-loop within the function body
        assert_equal(15.0, w.get_parser_string("let add_numbers_up_to(a, b) = {let c = a; let sum = 0; while c <= b do {sum+=c; c+=1}; sum}; add_numbers_up_to(1, 5)"))

        # Test a function that takes two numbers,
        # and returns the largest one.
        # Uses a if-else within the function body
        assert_equal(10.0, w.get_parser_string("let return_largest_num(a, b) = {if a > b then {a} else {b}}; return_largest_num(5, 10)"))

        assert_equal(5, w.get_parser_string("let f(x, y) = {x*y + y}; let g(x) = {x + 1}; f(g(3), 1)"))
        assert_equal(2, w.get_parser_string("let f(x, y, z) = {x*y*z}; let g(x) = {x}; let h(x, y) = {x@y - y}; f(1, h(3, 1), g(1))"))
        assert_equal(36, w.get_parser_string("let f(x) = {x+2}; let g(x) = {6 * f(x)}; g(4)"))
    end
end


class TestScoping < Test::Unit::TestCase
    def test_if_scoping
        w = Whisper.new
        
        assert_equal(5.0, w.get_parser_string("let a = 5; if a == 5 then {let a = a + 1}; a"))
        assert_equal(6.0, w.get_parser_string("let a = 5; if a == 5 then {a += 1}; a"))
        assert_equal(0, w.get_parser_string("let a = 5; while a > 0 do {a -= 1}; a"))
        assert_equal(5, w.get_parser_string("let a = 5; while a > 0 do {let a = a - 1}; a"))
        assert_equal(1, w.get_parser_string("let a = 10000; while a > 1 do {a /= 10}; a"))
        assert_equal(1000000, w.get_parser_string("let a = 1; while a < 1000000 do {a *= 10}; a"))
    end

end

class TestRecursion < Test::Unit::TestCase
    def test_factorial
        w = Whisper.new

        assert_equal(1, w.get_parser_string("let factorial(n) = {if n == 0 then {1} else {n * factorial(n-1)}}; factorial(0)"))
        assert_equal(1, w.get_parser_string("let factorial(n) = {if n == 0 then {1} else {n * factorial(n-1)}}; factorial(1)"))
        assert_equal(2, w.get_parser_string("let factorial(n) = {if n == 0 then {1} else {n * factorial(n-1)}}; factorial(2)"))
        assert_equal(24, w.get_parser_string("let factorial(n) = {if n == 0 then {1} else {n * factorial(n-1)}}; factorial(4)"))
        assert_equal(5040, w.get_parser_string("let factorial(n) = {if n == 0 then {1} else {n * factorial(n-1)}}; factorial(7)"))
        assert_equal(39916800, w.get_parser_string("let factorial(n) = {if n == 0 then {1} else {n * factorial(n-1)}}; factorial(11)"))
    end

    def test_fibonacci 
        w = Whisper.new

        assert_equal(0, w.get_parser_string("let fib(x) = {if x <= 0 then {0} else {if x == 1 then {1} else {fib(x-2) + fib(x-1)}}}; fib(0)"))
        assert_equal(1, w.get_parser_string("let fib(x) = {if x <= 0 then {0} else {if x == 1 then {1} else {fib(x-2) + fib(x-1)}}}; fib(1)"))
        assert_equal(1, w.get_parser_string("let fib(x) = {if x <= 0 then {0} else {if x == 1 then {1} else {fib(x-2) + fib(x-1)}}}; fib(2)"))
        assert_equal(2, w.get_parser_string("let fib(x) = {if x <= 0 then {0} else {if x == 1 then {1} else {fib(x-2) + fib(x-1)}}}; fib(3)"))
        assert_equal(3, w.get_parser_string("let fib(x) = {if x <= 0 then {0} else {if x == 1 then {1} else {fib(x-2) + fib(x-1)}}}; fib(4)"))
        assert_equal(5, w.get_parser_string("let fib(x) = {if x <= 0 then {0} else {if x == 1 then {1} else {fib(x-2) + fib(x-1)}}}; fib(5)"))
    
      # The following are quite slow. The are here should they wish to be ran, but keep in mind it gets quite slow.
      #
      # assert_equal(89, w.get_parser_string("let fib(x) = {if x <= 0 then {0} else {if x == 1 then {1} else {fib(x-2) + fib(x-1)}}}; fib(11)"))
      # assert_equal(34, w.get_parser_string("let fib(x) = {if x <= 0 then {0} else {if x == 1 then {1} else {fib(x-2) + fib(x-1)}}}; fib(9)"))
      # assert_equal(233, w.get_parser_string("let fib(x) = {if x <= 0 then {0} else {if x == 1 then {1} else {fib(x-2) + fib(x-1)}}}; fib(13)"))
    end

end

class Test_Array < Test::Unit::TestCase
    def test_make_array 
        w = Whisper.new

        assert_equal([], w.get_parser_string("[]"))
        assert_equal([1], w.get_parser_string("[1]"))
        assert_equal([1, 2, 3, 4, 5], w.get_parser_string("[1, 2, 3, 4, 5]"))
    end

    def test_array_index 
        w = Whisper.new

        assert_equal(19, w.get_parser_string("let a = [2, 3, 5, 7]; let a[0] = 19; a[0]"))
        assert_equal([], w.get_parser_string("let a = []; a"))
        assert_equal(7, w.get_parser_string("let a = [2,3 , 4, 7]; a[-1]"))
        assert_equal(3, w.get_parser_string("let a = [2, 3, 5]; a[1]"))
        assert_equal(3, w.get_parser_string("let a = [2,3,5]; a[-2]"))
        assert_equal(nil, w.get_parser_string("let a = [1,2,3,4]; a[222]"))
    end

    def test_array_access_nested
        w = Whisper.new

        assert_equal([], w.get_parser_string("let a = [[], [1,2,3], [[4], 5], [7,8], 9]; a[0]"))
        assert_equal([1,2,3], w.get_parser_string("let a = [[], [1,2,3], [[4], 5], [7,8], 9]; a[1]"))
        assert_equal(3, w.get_parser_string("let a = [[], [1,2,3], [[4], 5], [7,8], 9]; a[1][2]"))
        assert_equal(4, w.get_parser_string("let a = [[], [1,2,3], [[4], 5], [7,8], 9]; a[2][0][0]"))
        assert_equal(9, w.get_parser_string("let a = [[], [1,2,3], [[4], 5], [7,8], 9]; a[-1]"))
        assert_equal(8, w.get_parser_string("let a = [[], [1,2,3], [[4], 5], [7,8], 9]; a[-2][1]"))
        assert_equal(7, w.get_parser_string("let a = [[], [1,2,3], [[4], 5], [7,8], 9]; a[-2][0]"))
        assert_equal([4], w.get_parser_string("let a = [[], [1,2,3], [[4], 5], [7,8], 9]; a[2][0]"))
        assert_equal([], w.get_parser_string("let a = [[[], [1,[2,[3]]]], [1,2,3], [[4], 5], [7,8], 9]; a[0][0]"))
        assert_equal(1, w.get_parser_string("let a = [[[], [1,[2,[3]]]], [1,2,3], [[4], 5], [7,8], 9]; a[0][1][0]"))
        assert_equal(3, w.get_parser_string("let a = [[[], [1,[2,[3]]]], [1,2,3], [[4], 5], [7,8], 9]; a[0][1][1][1][0]"))
        assert_equal(2, w.get_parser_string("let a = [[[], [1,[2,[3]]]], [1,2,3], [[4], 5], [7,8], 9]; a[0][1][1][0]"))
        assert_equal([4], w.get_parser_string("let a = [[[], [1,[2,[3]]]], [1,2,3], [[4], 5], [7,8], 9]; a[2][0]"))
        assert_equal([[], [1,[2,[3]]]], w.get_parser_string("let a = [[[], [1,[2,[3]]]], [1,2,3], [[4], 5], [7,8], 9]; a[0]"))
        assert_equal(5, w.get_parser_string("let a = [[[], [1,[2,[3]]]], [1,2,3], [[4], 5], [7,8], 9]; a?size"))
    end

    def test_array_assign 
        w = Whisper.new

        assert_equal(nil, w.get_parser_string("let a = [1,2,3]; let a[888] = 12; a[888]"))
        assert_equal([1,2,3], w.get_parser_string("let a = [1,2,3]; let a[888] = 12; a"))
        assert_equal([1,2,999], w.get_parser_string("let a = [1,2,3]; let a[-1] = 999; a"))
        assert_equal([7,8,9], w.get_parser_string("let a = [1,2,3]; let a[0] = 7; let a[1] = 8; let a[2] = 9; a"))
        assert_equal([], w.get_parser_string("let a = []; let a[0] = 2; a")) 
    end

    def test_array_addition
        w = Whisper.new
        
        assert_equal([1,2,3,4,5,6], w.get_parser_string("[1,2,3] + [4,5,6]"))
        assert_equal([1,2,3,4,5,6], w.get_parser_string("let a = [1,2,3]; let a = a + [4,5,6]; a"))
        assert_equal([1,2,3,4,5,6], w.get_parser_string("let a = [1,2,3]; let b = [4,5,6]; a+b"))
        assert_equal([1,2,3,4,5,6], w.get_parser_string("let a = [1,2,3]; let b = [4,5,6]; let c = a+b; c"))
        assert_equal([1,2,3], w.get_parser_string("let a = [1,2,3]; let a = a + []; a"))
        assert_equal([1,2,3], w.get_parser_string("let a = [1,2,3]; let b = []; a + b"))
        assert_equal([], w.get_parser_string("let a = []; let b = []; let c = a + b; c"))
    end

    def test_array_subtraction
        w = Whisper.new

        assert_equal([], w.get_parser_string("[]-[]"))
        assert_equal([], w.get_parser_string("[1,2,3] - [1,2,3]"))
        assert_equal([1,2,3], w.get_parser_string("let a = [1,2,3,4,5,6]; let b = [4,5,6]; let c = a - b; c"))
    end

    def test_array_empty 
        w = Whisper.new

        assert_equal(true, w.get_parser_string("let a = []; a?empty"))
        assert_equal(false, w.get_parser_string("let a = [8]; a ? empty"))
        assert_equal(false, w.get_parser_string("[5] ? empty"))
        assert_equal(true, w.get_parser_string("[]?empty"))
        assert_equal(true, w.get_parser_string("([1,2,3] - [3,2,1]) ? empty"))
    end

    def test_array_size
        w = Whisper.new

        assert_equal(0, w.get_parser_string("let a = []; a ?size"))
        assert_equal(1, w.get_parser_string("let a = [8]; a ? size"))
        assert_equal(20, w.get_parser_string("let a = [1,2,3,4,5,6,7,8,9,10,11,12,113,14,15,16,17,18,19,20]; a?size"))
        assert_equal(0, w.get_parser_string("[]?size"))
        assert_equal(1, w.get_parser_string("[9] ? size"))
        assert_equal(10, w.get_parser_string("[1,1,1,1,1,1,1,1,5,6] ? size"))
    end

    def test_array_sort
        w = Whisper.new

        assert_equal([1,2,3,4,5], w.get_parser_string("let a = [5, 1, 3, 2, 4]; a! sort; a"))
        assert_equal([], w.get_parser_string("let a = []; a!sort; a"))
        assert_equal([1,2,3], w.get_parser_string("let a = [1,2,3]; a ! sort; a"))
        assert_equal([], w.get_parser_string("[]!sort"))
        assert_equal([2,3], w.get_parser_string("[3,2] ! sort"))
        assert_equal([1,2,3,4,5,6], w.get_parser_string("[4,1,6,2,5,3]! sort"))
    end

    def test_array_flip
        w = Whisper.new

        assert_equal([0,0,0,0,1,1,1,1], w.get_parser_string("let a = [1,1,1,1,0,0,0,0]; a! flip; a"))
        assert_equal([], w.get_parser_string("let a = []; a !flip; a"))
        assert_equal([9,8,7,6,5,4,3,2,1], w.get_parser_string("let a = [1,2,3,4,5,6,7,8,9]; a ! flip; a"))
        assert_equal([0,0,0,0,1,1,1,1], w.get_parser_string("[1,1,1,1,0,0,0,0]!flip"))
        assert_equal([], w.get_parser_string("[] ! flip"))
        assert_equal([9,8,7,6,5,4,3,2,1], w.get_parser_string("[1,2,3,4,5,6,7,8,9] ! flip"))
    end

    def test_array_set
        w = Whisper.new

        assert_equal([1,2,3], w.get_parser_string("let a = [3,3,3,3,3,1,1,1,1,1,2,2,2]; a!set"))
        assert_equal([], w.get_parser_string("[] ! set"))
        assert_equal([8], w.get_parser_string("[8]!set"))
        assert_equal([-1, 0, 1], w.get_parser_string("let a = [0, -1, 1]; a ! set"))
    
    end

    def test_array_naturals 
        w = Whisper.new

        assert_equal([], w.get_parser_string("let a = N{-6}; a"))
        assert_equal([0], w.get_parser_string("N{0}"))
        assert_equal([0, 1, 2, 3, 4, 5], w.get_parser_string("N{5}"))
        assert_equal([1,2,3,4,5], w.get_parser_string("N{5} - [0]"))
    end

    def test_array_primes
        w = Whisper.new

        assert_equal([], w.get_parser_string("Primes{1}"))
        assert_equal([2], w.get_parser_string("Primes{2}"))
        assert_equal([2, 3, 5, 7, 11, 13, 17, 19, 23], w.get_parser_string("Primes{24}"))
    end

    def test_array_map
        w = Whisper.new

        assert_equal([true, false, true], w.get_parser_string("let f(x) = {x % 2 == 0}; let a = [2,3,4]; a.map(f)"))
        assert_equal([2,4,6,8,10], w.get_parser_string("let f(x) = {2*x}; [1,2,3,4,5].map(f)"))
        assert_equal([], w.get_parser_string("let f(c) = {c@3 + c@5}; [].map(f)"))
        assert_equal([100], w.get_parser_string("let f(x) = {x@2}; [10].map(f)"))
    end

    def test_array_filter
        w = Whisper.new
        
        assert_equal([2, 3, 5, 7], w.get_parser_string("let f(x) = {x?prime}; [1,2,3,4,5,6,7,8].filter(f)"))
        assert_equal([0,3,6,9], w.get_parser_string("let f(x) = {x % 3 == 0}; N{10}.filter(f)"))
        assert_equal([5], w.get_parser_string("let f(x) = {x %5 == 0}; Primes{100}.filter(f)"))
        assert_equal([1, 3, 5, 7, 9], w.get_parser_string("let f(x) = {x%2!=0}; let a = N{10} - [0]; a.filter(f)"))
        assert_equal([], w.get_parser_string("let f(x) = {x@100}; [].filter(f)"))
    end


    def test_for_loop 
        w = Whisper.new

        assert_equal(nil, w.get_parser_string("for x in [] do {x+ 9}"))
        assert_equal(100, w.get_parser_string("for x in [1,2,3,4,5,6,7,8,9,10] do {x@2}"))
        assert_equal(nil, w.get_parser_string("for x in [1,2,3] do {y + 3}"))
        assert_equal(361, w.get_parser_string("for x in Primes{20} do {x@2}"))
        assert_equal(17, w.get_parser_string("for natural in (N{40} - [35,36,37,38,39,40]) do {natural / 2}"))
        assert_equal(0, w.get_parser_string("for num in Primes{20} - N{10} + [100] do {num % 20}"))
        assert_equal(5, w.get_parser_string("for num in Primes{20} - N{10} + [100] do {num / 20}"))
    end
end

class Test_Primality < Test::Unit::TestCase
    #
    # Test the function prime?
    
    def test_prime 
        w = Whisper.new

        assert_equal(true, w.get_parser_string("let a = 2; a?prime"))
        assert_equal(false, w.get_parser_string("let a = 1; a ? prime"))
        assert_equal(true, w.get_parser_string("let a = 999983; a ?prime"))
        assert_equal(true, w.get_parser_string("let a = 97; a ? prime"))
        assert_equal(false, w.get_parser_string("let a = 99; a?prime"))
        assert_equal(false, w.get_parser_string("let a = 2.1; a?prime"))
        
        # 2.0 is a double, not an integer. Primality is only relevant for positive integers.
        assert_equal(false, w.get_parser_string("let a = 2.0; a ? prime"))
    end
end

class Test_Record < Test::Unit::TestCase
    #
    # Test creation and use of Records

    def test_record_create
        w = Whisper.new
        
        assert_equal({"height"=>5, "width"=>2.5}, w.get_parser_string("let Box = {height = 5; width = 2.5}"))
        assert_equal({"height"=> 5, "width"=>3.1 }, w.get_parser_string("let Boxes = {box1 = {height = 5; width = 3.1}; box2 = {height = 7; width = 5}}; Boxes.box1"))
        assert_equal(5, w.get_parser_string("let Boxes = {box1 = {height = 5; width = 3.1}; box2 = {height = 7; width = 5}}; Boxes.box1.height"))
        assert_equal(3.1, w.get_parser_string("let Boxes = {box1 = {height = 5; width = 3.1}; box2 = {height = 7; width = 5}}; Boxes.box1.width"))
        assert_equal({"height"=>7, "width"=>5}, w.get_parser_string("let Boxes = {box1 = {height = 5; width = 3.1}; box2 = {height = 7; width = 5}}; Boxes.box2"))
        assert_equal(7, w.get_parser_string("let Boxes = {box1 = {height = 5; width = 3.1}; box2 = {height = 7; width = 5}}; Boxes.box2.height"))
        assert_equal(5, w.get_parser_string("let Boxes = {box1 = {height = 5; width = 3.1}; box2 = {height = 7; width = 5}}; Boxes.box2.width"))
    end
end
