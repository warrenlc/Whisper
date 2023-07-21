#!/usr/bin/env ruby

# Authors: Viktor Norlin && Warren Crutcher

require 'logger'

require_relative '../classes/nodes'
require_relative '../classes/scope'
require_relative '../parser/parser'

LOGGER  = false 
TESTING = false

##############################################################################
#
# This part defines the Whisper language
#
##############################################################################

class Whisper 

  def initialize
    @whisper_parser = Parser.new("whisper") do
      
      # Arithmetic operators
      token(/\+\=/)                   {|m| m}
      token(/\-\=/)                   {|m| m}
      token(/\*\=/)                   {|m| m}
      token(/\/\=/)                   {|m| m}
      token(/\%/)                     {|m| m}
      token(/\!\=/)                   {|m| m} 
      token(/\=\=/)                   {|m| m} 
      token(/[\+\-\*\/\@\%]/)         {|m| m}
      token(/\=/)                     {|m| m}
      token(/\!/)                     {|m| m}
      token(/\&\&/)                   {|m| m}
      token(/\|\|/)                   {|m| m}
      token(/\~/)                     {|m| m}
      token(/\<\</)                   {|m| m}
      token(/\>\>/)                   {|m| m}
      token(/\^/)                     {|m| m}
      token(/\|/)                     {|m| m}
      token(/\&/)                     {|m| m}

      # Array access
      token(/\[/)                     {|m| m}
      token(/\]/)                     {|m| m}
      
      # Record acces
      token(/\{/)                     {|m| m}
      token(/\}/)                     {|m| m}
      
      # Comparison operators
      token(/\<\=/)                   {|m| m}
      token(/\>\=/)                   {|m| m}
      token(/\</)                     {|m| m}
      token(/\>/)                     {|m| m}
     
      # Syntax markers
      token(/\:/)                     {|m| m}
      token(/\./)                     {|m| m}
      token(/\,/)                     {|m| m}
      token(/;/)                      {|m| m}
      token(/\(/)                     {|m| m}
      token(/\)/)                     {|m| m}
      token(/\?/)                     {|m| m}

      # Boolean literals
      token(/true/)                   {|m| m}
      token(/false/)                  {|m| m}
      
      # Keywords
      token(/show/)                   {|m| m}
      token(/prime/)                  {|m| m}
      token(/Primes/)                 {|m| m}
      token(/N/)                      {|m| m}
      token(/empty/)                  {|m| m}
      token(/size/)                   {|m| m}
      token(/sort/)                   {|m| m}
      token(/flip/)                   {|m| m}
      token(/set/)                    {|m| m}
      token(/continue/)               {|m| m}
      token(/break/)                  {|m| m}
      token(/for/)                    {|m| m}
      token(/in/)                     {|m| m}
      token(/let/)                    {|m| m}
      token(/if/)                     {|m| m}
      token(/else/)                   {|m| m}
      token(/then/)                   {|m| m}
      token(/do/)                     {|m| m}
      token(/while/)                  {|m| m}
      
      # Variable and function names
      token(/[a-z\_][a-zA-Z0-9\_]*/)  {|m| m}

      # Record Assignment names
      token(/[A-Z][a-zA-Z0-9\_]+/)    {|m| m}
      
      # Numbers / spaces
      token(/\s+/)                    # ignore spaces
      token(/\-?[0-9]+\.[0-9]*/)      {|m| m}
      token(/\-?\.?[0-9]+/)           {|m| m} 
      
      # Start Matching here
      start :program do 
        match(:statement_list) 
      end

      rule :statement_list do
        #
        # A program consists of a list of statements
        #
        match(:statement)                                         { |         stmt|        [stmt] }
        match(:statement_list, ';', :statement)                   { |list, _, stmt| [*list, stmt] }
      end

      rule :statement do
        #
        # Different statement types
        #
        match(:built_in_evaluate)     # Built-in functions: show, sort, size, flip, map, filter, set, empty
        match(:if_statement)          # if-then and if-then-else
        match(:while_statement)       # while <condition> do {...}
        match(:function_define)       # let f(...) = {...}
        match(:assignment_statement)  # let a = ...
        match(:for_each_statement)    # for x in <array> do {...}
        match(:break_statement)       # break a loop
        match(:continue_statement)    # do nothing in a loop iteration
        match(:expression)            # things that can be operated on

      end

      rule :built_in_evaluate do
        #
        # Built-in functions
        # Creates a Built-in function Node with the given function as parameter
        #
        match('show',      '(', :expression,    ')')              { |_,                   _, expr, _| Node_Built_In_Function.new("show",           expr) }
        match(:expression, '?', :inquiry)                         { |array,               _, inquiry| Node_Built_In_Function.new(inquiry,         array) }
        match(:expression, '!', :command )                        { |array,               _, command| Node_Built_In_Function.new(command,         array) }
        match(:expression, '.', :array_transform, '(', :id, ')')  { |array, _, transform, _, func, _| Node_Built_In_Function.new(transform, array, func) }
      end

      rule :inquiry do
        #
        # For Arrays, preceded with '?'
        # ex: <array> ? empty | [2,3,4,5] ? size 
        #
        match('empty')
        match('size')
      end

      rule :command do
        #
        # For Arrays, preceded with '!'
        # ex: <array> ! sort | <array>!flip | <array> ! set
        #
        match('sort') # Sorts an array with Ruby's sort! function
        match('flip') # Reverses an array with Ruby's reverse! function
        match('set')  # Sorts an array, reduces to unique elements
      end

      rule :array_transform do 
        #
        # For Arrays, apply a function to an array.
        # Uses '.' notation: <array>.map(<function>) | <array>.filter(<function>)
        # As of 23-5-2023, not chainable
        #
        match('map')
        match('filter')
      end

      rule :if_statement do
        #
        # Matches if-then-{block}-else-{block} and if-then-{block} statements 
        #
        match('if', :expression, 'then', '{', :statement_list, '}', 'else', '{', :statement_list, '}') { |_, condition, _, _, then_block, _, _, _, else_block, _ | 
                                                                                                          Node_If.new(condition, then_block, else_block)           
                                                                                                       }
        match('if', :expression, 'then', '{', :statement_list, '}')                                    { |_, condition, _, _, then_block, _| 
                                                                                                          Node_If.new(condition, then_block, nil)                  
                                                                                                       }
      end

      rule :while_statement do
        #
        # Matches while-condition-do-{block} statements
        #
        match('while', :expression, 'do', '{', :statement_list,  '}')                 { |_, cond, _, _, stmt, _| Node_While.new(cond, stmt) }
      end
      
      rule :function_define do 
        #
        # Matches syntax below to create a Node_Function_Define object
        #
        match('let', :id, '(', :argument_list, ')', '=', '{', :statement_list, '}')   { |_, id, _, args, _, _, _, stmts, _|
                                                                                        Node_Function_Define.new(id, args, stmts) 
                                                                                      }
      end

      rule :argument_list do
        #
        # Creates a Node_List whose members are arguments to a function
        #
        match(:id)                                                                    { |arg| Node_List.new([arg]) }
        match(:expression)                                                            { |arg| Node_List.new([arg]) } # To allow recursion...
        match(:argument_list, ',', :id)                                               { |list, _, args| Node_List.new([*list, args]) }

      end

      rule :assignment_statement do
        #
        # Differentiates between 'let' assignments and reassignments
        # 'let' assignments are affected by scope stack whereas reassignments
        # allow the user to reassign values from a different scope 
        # Allows also for reassigning elements of arrays, i.e. <array>[7] = 8
        # Does not yet support Record reassignments
        #
        match('let', :variable, '=', :built_in_evaluate)                      { |_, name, _, rhs| Node_Assignment.new(name.name, rhs)        }
        match('let', :id, '=', :expression)                                   { |_, name, _, rhs| Node_Assignment.new(name,      rhs)        }
        #
        # Reasign variables to new values
        match(:variable, :re_assign_op, :expression)                          { |variable, op, value| Node_Reassign.new(op, variable, value) }
        #
        # Reassign Array elements to new values
        match('let', :variable, '[', :expression, ']', '=', :expression)      { |_, array_variable, _, index, _, _, expr| 
                                                                                    Node_Array_Assignment.new(array_variable, index, expr) 
                                                                              }
        # Define new Records
        match('let', :record_name, '=', :record_fields)                       { |_, record_name,    _, record_fields,   | 
                                                                                    Node_Assignment.new(record_name.name, record_fields)   
                                                                              }
      end

      rule :for_each_statement do
        #
        # Iterate over the elements of an array and execute statements for each 
        # element in the array.
        # ex: for x in <array> do {...}
        #
        match('for', :id, 'in', :expression, 'do', '{', :statement_list, '}') { |_, variable, _, array, _, _, statements, _| 
                                                                                    Node_For_Each.new(variable, array, statements) 
                                                                              }
      end
      
      rule :break_statement do
        # 
        # Exit a loop immediately
        #
        match('break')                     { |break_| Node_Break.new }
      end

      rule :continue_statement do 
        #
        # Do nothing in a loop.
        # Same effect achieved by writing nothing.
        # Rather, continue statement adds clarity to programmer's intentions
        #
        match('continue')                  { |continue | Node_Continue.new }
      end
      
      rule :record_fields do
        # Matches the 'fields' of a Record assignment.
        # A Record is an associative data-structure, similar to a Hash
        # ex: {variable_name = value; variable_name = value; ... }
        #
        match(:id, '=', :expression)                         { |name,             _, expression|              [name, expression]  }
        match(:record_fields, ';', :id, '=', :expression)    { |records, _, name, _, expression| [[*records], [name, expression]] }
        match()                                              { [] }
      end

      rule :id do 
        #
        # Matches variable names without creating a Variable node
        #
        match(/[a-z\_]+[a-z0-9\_]*/)
        
      end

      rule :function_evaluate do
        #
        # Matches statements for executing functions
        #
        match(:id, '(', :explist, ')')                                  { |func, _, args, _| Node_Function_Call.new(func, args) }
      end

      rule :explist do
        #
        # Matches a list of expressions for function evaluation
        #
        match(:expression)                                              { |         exp| Node_List.new([exp])        }
        match(:explist, ',', :expression)                               { |list, _, exp| Node_List.new([*list, exp]) }
        match()                                                         { Node_List.new([]) } 
      end

      rule :expression do
        #
        # An expression can access the values in a Record, is a term (with many subdivisions listed below)
        # is a variable, or can be the 'continue' and 'break' statements.
        #
        match(:record_access)
        match(:term)
        match(:variable)
        match(:continue_statement)
        match(:break_statement)
      end

      rule :term do
        #
        # Matches logical (boolean) statements and arithmetic statements
        #
        match(:logical_term)
        match(:arithmetic_term)
      end

      rule :arithmetic_term do
        #
        # Arithmetic term subdivided accordingly to achieve the desired
        # priority for arithmetic operations
        #
        match(:arithmetic_factor)
        match(:arithmetic_term, :addop, :arithmetic_factor)             { |lhs, op, rhs| Node_Arithmetic.new(lhs, op, rhs) }
        match(:arithmetic_term, :rel_op, :arithmetic_factor)            { |lhs, op, rhs| Node_Comparison.new(lhs, op, rhs) }
      end

      rule :arithmetic_factor do
        #
        # Multiplication and division have higher priority than subtraction/addition
        #
        match(:arithmetic_exponential)
        match(:arithmetic_factor, :bitwise_op, :arithmetic_exponential) { |lhs, op, rhs| Node_Arithmetic.new(lhs, op, rhs) }
        match(:arithmetic_factor, :mulop, :arithmetic_exponential)      { |lhs, op, rhs| Node_Arithmetic.new(lhs, op, rhs) }
        match(:arithmetic_factor, :eq_op, :arithmetic_atom)             { |lhs, op, rhs| Node_Comparison.new(lhs, op, rhs) }
      end
      
      rule :arithmetic_exponential do
        #
        # Exponentiation has higher priority than multiplication and division
        #
        match(:array_access)
        match(:arithmetic_exponential, :exop, :array_access)            { |lhs, op, rhs| Node_Arithmetic.new(lhs, op, rhs) }
      end

      rule :array_access do
        #
        # Access the value of an Array at a given index,
        # including nested Arrays.
        # ex: let a = [2,[4, 5]]; a[1][0] = 4
        #
        match(:array_access, '[', :expression, ']')                     { |array, _ , expression, _| Node_Array_Access.new(array, expression) }
        match(:arithmetic_atom)
      end

      rule :arithmetic_atom do
        #
        # Atoms are the smallest units of arithmetic statements
        # Prime number Arrays and Natural number Arrays are treated as atoms.
        #
        # Allow the user to create an Array of prime numbers up to a given digit, using Sieve of Erasthones
        # i.e. Primes{20} = [2,3,5,7,11,13,17,19]
        match('Primes', '{', :digit, '}')                               { |_, _, digit, _| Node_Array_Primes.new(digit)      }
        match(:function_evaluate)
        #
        # literals are digits or variables
        match(:literal)
        match('(', :arithmetic_term, ')')                               { |_,     term, _| term                              }
        #
        # Allow the user to create an array of a subset of Natural numbers with a given upper bound.
        # i.e. N {9} = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]
        match('N', '{', :digit, '}')                                    { |_, _, digit, _| Node_Array_Naturals.new(digit)    }                                                                                 #         array_naturals = []
        #
        # Matches an Array literal
        match('[', :explist, ']')                                       { |_,    exprs, _| Node_Array.new(exprs)             }
        #
        # Matches the operation to negate an entire expression
        match(:unary_minus, :arithmetic_atom)                           { |op,        lhs| Node_Arithmetic.new(lhs, op, nil) }
        #
        # Matches Record Literals
        match('{', :record_fields, '}')                                 { |_,   fields, _| Node_Record.new(fields)           }
      end
      
      rule :logical_term do
        #
        # 'logical or' ( || ) has lowest priority for logical statements
        #
        match(:logical_factor)
        match(:logical_term, :orop, :logical_factor)                    { |lhs,   op, rhs| Node_Logical_Op.new(lhs, op, rhs) }
        
      end

      rule :logical_factor do
        #
        # 'logical and' ( && )
        #
        match(:logical_atom)
        match(:logical_factor, :andop, :logical_atom)                   { |lhs,  op, rhs| Node_Logical_Op.new(lhs, op, rhs) }
      end

      rule :logical_atom do
        #
        # Matches the smallest units of logical operations
        #
        match(:bool)
        #
        # Inquiry operation to check if an integer is prime.
        # 
        match(:literal, '?', /prime/)                                   { |integer, _, _|  Node_Built_In_Function.new("prime",  integer) }
        match('(', :logical_term, ')')                                  { |_, term,    _|  term                                          }
        match('!', :logical_atom)                                       { |_,        rhs|  Node_Logical_Op.new(nil, nil, rhs)            }
      end

      rule :re_assign_op do 
        #
        # Matches reassignment operations: 
        # +=, -= *=, /=
        match(:increment)   # +=
        match(:decrement)   # -=
        match(:re_divide)   # /=
        match(:re_multiply) # *=
      end

      #
      # Various unary and binary operations
      #

      rule :unary_minus do
        #
        # Negation and bitwise negation
        #
        match(/\-/) # For negating an entire arithmetic expression
        match(/~/)  # Bitwise signed negation
      end

      #
      # Reassignment operators. These 'cheat' scoping by
      # allowing the user to have sticky results of 
      # variable changes as scope level changes
      #
      rule :increment do
        match(/\+\=/)
      end

      rule :decrement do
        match(/\-\=/) 
      end

      rule :re_divide do 
        match(/\/\=/)
      end
      
      rule :re_multiply do 
        match(/\*\=/)
      end

      #
      # Bitwise arithmetic operations
      #
      rule :bitwise_op do
        match(/\<\</)    # Bitwise left shift  <<
        match(/\>\>/)    # Bitwise right shift >>
        match(/\&/)      # Bitwise And          &
        match(/\^/)      # Bitwise XOR          ^
        match(/\|/)      # Bitwise Or           |
      end
      
      # Addition | Subtraction
      #
      rule :addop do
        match(/\+/)
        match(/\-/)
      end

      # Multiplication | Division | Modulo
      #
      rule :mulop do
        match(/\*/)
        match(/\//)
        match(/\%/)
      end

      # Exponentiation
      # Uses '@', i.e. 2@3 = 2*2*2 = 8
      #
      rule :exop do
        match(/\@/)
      end

      # Logical ||
      rule :orop do
        match(/\|\|/)
      end

      # Logical &&
      rule :andop do
        match(/\&\&/)
      end

      # Relational operators
      rule :rel_op do
        match(/>/)   # greater than           >
        match(/</)   # less than              <
        match(/<=/)  # less than or equal    <=
        match(/>=/)  # greater than or equal >=
      end

      # Equality operators
      rule :eq_op do
        match(/==/) # equal     ==
        match(/!=/) # not equal !=
      end
 
      #
      # Variables
      rule :variable do
        #
        # Matches a variable name and creates a Node_Variable
        #
        match(/[a-z\_]+[a-z\_0-9]*/)                                { |variable_name| Node_Variable.new(variable_name) }
      end

      # Literals are either variables or digits
      rule :literal do
        #
        # Matches either a variable or a number
        #
        match(:digit)
        match(:variable)
      end

      # Digits are signed and either doubles or integers
      rule :digit do
        #
        # Matches numbers and creates either a Node_Double or
        # Node_Integer
        #
        match('-', /\.?[0-9]+/)                                      { |_, digit| if digit.include? ?. then 
                                                                                    Node_Double.new(digit.to_f*(-1))
                                                                                  else
                                                                                    Node_Integer.new(digit.to_i*(-1))
                                                                                  end                                 
                                                                     }

        match(/(\.?[0-9]+)/)                                         { |  digit|  if digit.include? ?. then 
                                                                                    Node_Double.new(digit.to_f)
                                                                                  else 
                                                                                    Node_Integer.new(digit.to_i)
                                                                                  end                                       
                                                                     }

        match('-', /[0-9]+\.[0-9]*/)                                 { |_, digit| Node_Double.new(digit.to_f*(-1)) }
        match(/\-?[0-9]+\.[0-9]*/)                                   { |   digit| Node_Double.new(digit.to_f)      } 
      end

      #
      # Boolean Values
      rule :bool do
        # Matches boolean literals
        match("true")                                                { Node_Boolean.new(true) }
        match("false")                                               { Node_Boolean.new(false) }
      end

      #
      # Record Access
      rule :record_access do
        #
        # Access the values at a given position in a Record
        # Still in Alpha Stage, i.e. does not process assymetric nesting structures
        # as of 25/5/2023
        #
        match(:record_name,   '.', :id)                              { |record_name,   _, field_name| Node_Record_Access.new(record_name,   field_name) }
        match(:record_access, '.', :id)                              { |record_access, _, field_name| Node_Record_Access.new(record_access, field_name) }
      end

      rule :record_name do
        #
        # Record names are always capitalized when declared.
        # can be normal variables when nested inside other Records
        #
        match(/[A-Z][a-zA-Z0-9\_]+/)                               
      end

    end

  end
  
  # Goodbye greeting to the user
  def done(str)
    ["quit","exit","bye","done",  ""].include?(str.chomp)
  end

  # Parser functions from original 'rdparse.rb'
  #

  # Parse the user string
  def get_parser_string str
    nodes = @whisper_parser.parse str

    last_result = nil
    for node in nodes
      last_result = node.eval
    end
    last_result
  end
  
  def read
    print "[Whisper]: "
    str = gets
    if done(str) then
      puts "Goodbye!"
    else
      puts "=> #{get_parser_string str}"
      read
    end
  end

  def log(state = false)
    if state
      @whisper_parser.logger.level = Logger::DEBUG
    end
  end
end

if !TESTING then
  Whisper.new.read
end
