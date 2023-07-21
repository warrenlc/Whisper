#!/usr/bin/env ruby

# Authors: Viktor Norlin && Warren Crutcher

require 'logger'

require_relative '../classes/nodes'
require_relative '../classes/scope'
require_relative '../parser/parser'

LOGGER = true
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
      token(/\!\=/)                   {|m| m} 
      token(/\=\=/)                   {|m| m} 
      token(/[\+\-\*\/\^\%]/)         {|m| m}
      token(/\=/)                     {|m| m}
      token(/\!/)                     {|m| m}
      token(/\&\&/)                   {|m| m}
      token(/\|\|/)                   {|m| m}
     
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

      # Boolean literals
      token(/true/)                   {|m| m}
      token(/false/)                  {|m| m}
      
      # Keywords
      token(/let/)                    {|m| m}
      token(/if/)                     {|m| m}
      token(/else/)                   {|m| m}
      token(/then/)                   {|m| m}
      token(/do/)                     {|m| m}
      token(/while/)                  {|m| m}
      token(/{/)                      {|m| m}
      token(/}/)                      {|m| m}
      token(/[A-Z]+/)                 {|m| m}
      token(/[a-z\_][a-zA-Z0-9\_]*/)  {|m| m}
      token(/show/)                   {|m| m}
      token(/union/)                  {|m| m}
      token(/set/)                    {|m| m}
      
      # Numbers / spaces
      token(/\s+/)                    # ignore spaces
      token(/\-?[0-9]+\.[0-9]*/)      {|m| m}
      token(/\-?\.?[0-9]+/)           {|m| m} 
      
      # Start Matching here
      start :program do 
        match(:statement_list) 
      end

      rule :statement_list do
        match(:statement)                       { |stmt| [stmt] }
        match(:statement_list, ';', :statement) { |list, _, stmt| [*list, stmt] }
      end

      rule :statement do
        match(:built_in_evaluate)
        match(:for_statement) 
        match(:if_statement)
        match(:while_statement)
        match(:function_assign)
        match(:assignment_statement)
        match(:function_evaluate)
        match(:expression)
      end

      rule :built_in_evaluate do
        match('show', '(', :expression, ')')  { |_, _, expr, _| Node_Built_In_Function.new("show", expr) }
        match('union', '(', :set_list, ')')   { |_, _, sets, _| Node_Built_In_Function.new("union", sets) }
      end
      
      rule :function_assign do 
        match('let', :id, '(', ')', '=', '{', :statement_list, '}')                   { |_, id, _, _, _, _, stmts, _| 
                                                                                        Node_Function_Define.new(id, nil, stmts) 
                                                                                      }
        match('let', :id, '(', :argument_list, ')', '=', '{', :statement_list, '}')   { |_, id, _, args, _, _, _, stmts, _|
                                                                                        Node_Function_Define.new(id, args, stmts) 
                                                                                      }
      end

      rule :argument_list do
        match(:id)                      { |arg| Node_List.new([arg]) }
        match(:argument_list, ',', :id) { |list, _, args| Node_List.new([*list, args]) }
      end

      rule :set_list do 
        match(:set_id)                 { |set| Node_List.new([set]) }
        match(:set)                    { |set| Node_List.new([set]) }
        match(:set_list, ',', :set_id) { |list, _, set| Node_List.new([*list, set]) }
        match(:set_list, ',', :set)    { |list, _, set| Node_List.new([*list, set]) }
      end

      rule :if_statement do 
        match('if', :expression, 'then', '{', :statement_list, '}', 'else', '{', :statement_list, '}') { |_, condition, _, _, then_block, _, _, _, else_block, _ | 
                                                                                                          Node_If.new(condition, then_block, else_block) 
                                                                                                       }
        match('if', :expression, 'then', '{', :statement_list, '}')                                    { |_, condition, _, _, then_block, _| 
                                                                                                          Node_If.new(condition, then_block, nil) 
                                                                                                       }
      end

      rule :while_statement do
        match('while', :expression, 'do', '{', :statement_list,  '}')  { |_, cond, _, _, stmt, _| Node_While.new(cond, stmt) }
      end

      rule :assignment_statement do 
        match('let', :id, '=', :expression)                            { |_, name, _, rhs| Node_Assignment.new(name, rhs) }
        match('let', :set_id, '=', :set)                               { |_, name, _, content| Node_Assignment.new(name, content) }
      end

      rule :id do 
        match(/[a-z\_][a-zA-Z0-9\_]*/)
      end

      rule :set_id do
        match(/[A-Z]+/)                                              # { |set_name| Node_Variable.new(set_name) }
      end

      rule :set do
        match('{', :digit, ',', '.', '.', ',', :digit, '}' )          { |_, first, _, _, _, _, last, _| 
                                                                        Node_Set.new(((first.val)..(last.val)).to_a) 
                                                                      }
        match('{', :digit_list, '}')                                  { |_, list, _| Node_Set.new(list.map!(&:eval)) }
        match('{', '}')                                               { |_, _| Node_Set.new([]) }
        match('{', :digit, '}')                                       { |_, number, _| Node_Set.new([number.val]) }
      end

      rule :function_evaluate do
        match(:id, '(', ')')                                          { |func, _, _,| Node_Function_Call.new(func, nil) } 
        match(:id, '(', :explist, ')')                                { |func, _, args, _| Node_Function_Call.new(func, args) }
      end

      rule :explist do
        match(:expression)                                            { |exp| Node_List.new([exp]) }
        match(:explist, ',', :expression)                             { |list, _, exp| Node_List.new([*list, exp]) }
      end

      rule :digit_list do 
        match(:digit)                                                 { |digit| [digit] } #Node_List.new([digit]) }
        match(:digit_list, ',', :digit)                               { |list, _, digit| [*list, digit] }#Node_List.new([*list, digit]) }
      end

      rule :expression do
        match(:term)
        match(:variable)
      end

      rule :term do
        match(:logical_term)
        match(:arithmetic_term)
      end

      rule :arithmetic_term do
        match(:arithmetic_factor)
        match(:arithmetic_term, :addop, :arithmetic_factor)          { |lhs, op, rhs| Node_Arithmetic.new(lhs, op, rhs) }
        match(:arithmetic_term, :rel_op, :arithmetic_factor)         { |lhs, op, rhs| Node_Comparison.new(lhs, op, rhs) }
      end

      rule :arithmetic_factor do
        match(:arithmetic_exponential)
        match(:arithmetic_factor, :mulop, :arithmetic_exponential)   { |lhs, op, rhs| Node_Arithmetic.new(lhs, op, rhs) }
        match(:arithmetic_factor, :eq_op, :arithmetic_atom)          { |lhs, op, rhs| Node_Comparison.new(lhs, op, rhs) }
      end

      rule :arithmetic_exponential do
        match(:arithmetic_atom)
        match(:arithmetic_exponential, :exop, :arithmetic_atom)      { |lhs, op, rhs| Node_Arithmetic.new(lhs, op, rhs) }
      end

      rule :arithmetic_atom do
        match(:literal)
        match('(', :arithmetic_term, ')')                            { |_, term, _| term}
        match(:unary_minus, :arithmetic_atom)                        { |op, lhs| Node_Arithmetic.new(lhs, op, nil) }
      end

      rule :logical_term do
        match(:logical_factor)
        match(:logical_term, :orop, :logical_factor)                 { |lhs, op, rhs| Node_Logical_Op.new(lhs, op, rhs) }
      end

      rule :logical_factor do
        match(:logical_atom)
        match(:logical_factor, :andop, :logical_atom)                { |lhs, op, rhs| Node_Logical_Op.new(lhs, op, rhs) }
      end

      rule :logical_atom do
        match(:bool)
        match('(', :logical_term, ')')                               { |_, term, _| term }
        match('!', :logical_atom)                                    { |_, rhs| Node_Logical_Op.new(nil, nil, rhs) }
      end

      rule :unary_minus do
        match(/\-/)
      end
          
      rule :addop do
        match(/\+/)
        match(/\-/)
      end

      rule :mulop do
        match(/\*/)
        match(/\//)
      end

      rule :exop do
        match(/\^/)
      end

      rule :orop do
        match(/\|\|/)
      end

      rule :andop do
        match(/\&\&/)
      end

      rule :rel_op do
        match(/>/)
        match(/</)
        match(/<=/)
        match(/>=/)
      end

      rule :eq_op do
        match(/==/)
        match(/!=/)
      end
 
      rule :variable do
        match(/[a-zA-Z\_][a-zA-Z\_0-9]*/)                     { |variable_name| Node_Variable.new(variable_name) }
      end

      rule :literal do
        match(:digit)
        match(:variable)
      end

      rule :digit do
        match(/\-?\.?[0-9]+/)                                 { |digit| if digit.include? ?. then 
                                                                          Node_Double.new(digit.to_f)
                                                                        else 
                                                                          Node_Integer.new(digit.to_i)
                                                                        end 
                                                              }
        match(/\-?[0-9]+\.[0-9]*/)                            { |digit| Node_Double.new(digit.to_f) } 
      end

      rule :bool do
        match("true")                                         { Node_Boolean.new(true) }
        match("false")                                        { Node_Boolean.new(false) }
      end

    end

  end
  
  def done(str)
    ["quit","exit","bye","done",  ""].include?(str.chomp)
  end

  def get_parser_string str
    nodes = @whisper_parser.parse str

    last_result = nil
    for node in nodes
      last_result = node.eval
    end
    last_result
  end
  
  def read
    print "[whisper] "
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
