# Authors: Warren Crutcher & Viktor Norlin
# The Nodes are all in alphabetical order
# or the search function is also helpful :-)

require_relative './scope'

##
# AST node for Arithmetic expressions

class Node_Arithmetic
    ##
    # Creates a Node to represent arithmetic expressions
    # Has attributes @lhs, @op and @rhs
    # where @op is the operation, @lhs and @rhs the
    # operands which may be nil

    attr_accessor :lhs, :op, :rhs
    def initialize(lhs, op, rhs)
        ##
        # Initialize the node with two children:
        # a left-hand side expression @lhs and a right-hand
        # side of the expression @rhs. The node itself is the operand
        # @op.

        @lhs = lhs
        @op = op
        @rhs = rhs
    end

    def show
        ##
        # Prints @lhs, @op, @rhs
        print "#{lhs.to_s}, #{op.to_s}, #{rhs.to_s}"
    end

    def eval
        ##
        # Evaluate the arithmetic expression reprsented by this node
        # and it's children nodes. In some cases, there will only be one
        # child node.
        # Wrap the entire function to avoid crashing for NoMethodError
        # For unary operations, We only have one child node
        # 
        begin
            if !@rhs && @lhs then
                #if @lhs then
                case @op 
                when '-'
                    return (-1)*@lhs.eval
                when '~'
                    return ~@lhs.eval
                end
            end
        
            if @lhs.eval && @rhs.eval then 
            # We use @ instead of ** for raising to a power
                case @op
                when '@'
                    @op = '**'
                when '/'
                    return @lhs.eval.to_f.send(@op, @rhs.eval.to_f)
                end
                    return @lhs.eval.send(@op, @rhs.eval)

            end
        rescue NoMethodError
            puts "Could not perform operation.\n"
            return nil
        rescue TypeError
            puts "Could not perform operation.\n"
            return nil
        rescue UndefinedSymbolError
            puts "Variable must first be declared.\n" 
        end
    end

end

##
# AST Node for representing Arrays

class Node_Array 
    ##
    # Creates a Node to represent Arrays
    # Attrbutes are @expressions (an Array)
    # and @size, the number of elements in
    # @expressions

    attr_accessor :expressions, :size

    def initialize(expressions)
        ##
        # This node has an Array of expressions
        # and a size being the number of expressions 
        @expressions = expressions
        @size = expressions.size
    end

    ##
    # Overloading of each funtion
    def each
        @expressions.each
    end

    def eval
        ##
        # Returns @expressions after calling
        # eval on every node in the @expressions
        # array

        @expressions.map(&:eval)
    end

end

##
# AST Node for accessing Array elements
class Node_Array_Access
    ##
    # Creates an AST Node to access the elements of
    # an array. 
    #
    # Attributes @name and @index are used to find
    # the value in ScopeManager

    attr_accessor :name, :index

    def initialize(name, index)
        ##
        # Bind the name of the array and the desired
        # index to this node.
        @name = name
        @index = index
    end

    def eval
        ##
        # This function returns a call to the eval function
        # of it's child which is the expression at the desired
        # array index
        #
        # Nested Arrays behave differently.
        # We cannot be sure the inner arrays are evaluated
        # yet
        if @name.is_a? Node_Array_Access then
            array = @name.eval
            
            # Handle out of bounds cases
            if not array[@index.eval] then
                puts "Nothing. You are out of bounds.\nTry an index between 0 and #{value.size - 1} or -1 for 'last' element.\n"
                return 
            end
            return array[@index.eval]
        end

        # If the array does not consist of Array nodes (not nested)
        value = ScopeManager.symbol_lookup(@name.name)
        index = @index.eval

        # Handle out of bounds cases
        if not value[index] then
            puts "Nothing. You are out of bounds.\nTry an index between 0 and #{value.size - 1} or -1 for 'last' element.\n"
            return 
        end

        return value[index]
    end

end

##
# AST Node for re-assigning elements of an array

class Node_Array_Assignment
    ##
    # Node for assigning a new value to an element of an array at the given index.
    # Attributes are the @name of the array, the @index in question
    # and the new @expression to be assigned to that index

    attr_accessor :name, :index, :expression

    def initialize(name, index, expression)
        ##
        # Reassign individual expressions in an array
        #
        # Bind the name of the array, the desired index
        # and the new expression
        #
        @name = name
        @index = index
        @expression = expression
    end

    def eval
        ##
        # Returns a call to eval function of the 
        # new expression at the desired array index
        #

        # Look up the array at the given location
        value = ScopeManager.symbol_lookup(@name.name)
        
        # Check for out of bounds indices
        if @index.eval > value.size - 1 then
            puts "You are out bounds!\nTry indices between 0 and #{value.size - 1} or -1 for 'last' element.\n"
            return
        end
        index = @index.eval
        
        # Return the value at the index
        value[index] = @expression.eval
    end
end

##
# Node to represent an array of Natural numbers (and 0)

class Node_Array_Naturals < Node_Array
    ##
    # Inherits from Node_Array
    #
    # Attributes include @size and @expressions

    attr_accessor :size, :expressions

    def initialize(bound, expressions=[]) 
        ##
        # Behaves like a normal array, only 
        # we know which values will be inside, namely
        # natural numbers (and 0) up to the given
        # upper bound
        #

        # @expressions should be empty
        @expressions = expressions

        # Check user given boundary
        if bound.val < 0 then
            puts "Natural numbers are positive integers and (in this case) also zero, you gave #{bound.val}.\n"
            puts "Giving you an empty array instead.\n"
             []
        else
            # Fill @expressions with Natural numbers up to the given boundary
            (0..bound.val).to_a.each { |x|
                @expressions << Node_Integer.new(x)
            }        
        end
    end

    def each
        super
    end

    def eval 
        super
    end
end

##
# Node Array that holds Prime numbers

class Node_Array_Primes < Node_Array
    ##
    # Behaves as a normal Node_Array
    # but only has prime numbers

    attr_accessor :size, :expressions

    def initialize(bound, expressions=[])
        ##
        # Given an upper bound, create an array
        # of all prime numbers up to that bound.
        # Function uses the Sieve of Erasthones to do
        # this quickly.

        # initialize @expressions
        @expressions = expressions

        # Check user-given boundary
        if bound.val < 2 then
            puts "2 is the smallest prime, you entered #{bound.val}.\nGiving you an empty array instead.\n"
            []
        else
            # Do the Sieve of Erasthones to make a Node_Array of primes
            # First create an array to just beyond
            # the supplied boundary, filled with 'true'
            prime_array = Array.new(bound.val+1, true)

            # Set 0 and 1 to false (they are not prime)
            prime_array[0] = prime_array[1] = false

            # start at the first prime number
            p = 2
            while p*p <= bound.val 

                # up to the sqr root of the boundary
                # set to 'false' any values that are factors of
                # boundary
                if prime_array[p] then
                    (p*p).step(bound.val, p) do |x|
                    prime_array[x] = false
                    end
                end
                p += 1
            end

            # Use the sieve to fill @expressions with 
            # the prime values
            (2..(bound.val)).each do |x|
                @expressions << Node_Integer.new(x) if prime_array[x]
            end
            # set the size
            @size = prime_array.count(true)
        end
    end

    def each
        super
    end
    
    def eval 
        super
    end

end

##
# AST node for assignments

class Node_Assignment
    ##
    # An assignment Node binds a variable
    # to a value using ScopeManager

    attr_accessor :name, :rhs

    def initialize(name, rhs)
        ##
        # Bind the name of the variable to be assigned
        # and the child node which is the right-hand side
        # of the expression: (example) "let a = <@rhs>"
        #
        @name = name
        @rhs  = rhs
    end
    
    def eval
        ##
        # Bind the value in the current scope
        # see ScopeManger class in scope.rb for details

        ScopeManager.symbol_create(@name, @rhs.eval)
    end
end

#
# AST Node for boolean expressions

class Node_Boolean
    ##
    # A node to represent either true or false

    attr_accessor :val
    def initialize(val)
        ##
        # A boolean node has no children, i.e. it is a leaf-node.
        # It only contains its own value
        #
        @val = val
    end

    def show
        ##
        # print the boolean value
        #
      p val
    end

    def eval
        ##
        # Return the value of this expression
        #
        @val
    end
end

##
# Break Statement Node
class Node_Break 
    ##
    # Terminal node to represent a break statement
    #
    def eval
        ##
        # Returns itself
        #
        self
    end
end

##
# This Node handles calls to Whisper's inbuilt functions
# show, size, empty, set, sort, map, filter

class Node_Built_In_Function 
    ##
    # a Built in function has a name, an argument, and possibly a function (map and filter)

    attr_accessor :name, :argument, :function

    def initialize(name, arg, function=nil) 
        ##
        # Bind the name of the built-in function to be called and
        # the argument to evaluate the function.
        #
        # Optional 'function' argument for built-in functions that
        # may require a function argument, namely 'map' and 'filter'
        #
        # The available built-in functions are:
        #
        # show   -> prints an evaluation of the node
        # prime  -> returns true or false if the Node_Integer calling this is prime or not
        # empty  -> returns true or false if the Node_Array calling this has size 0 or not
        # size   -> returns the number of expressions in a Node_Array
        # sort   -> sorts an Array
        # flip   -> reverses an Array
        # set    -> sorts an array and removes 'extraneous' elements
        # map    -> takes a function as argument, applies the function to each expression in the array
        # filter -> takes a function as argument, applies the function to each expression, removing
        #           those that return 'false'
        #
        @name = name
        @argument = arg
        @function = function
    end

    def array_control(message)
        ##
        # Check that the functions that should
        # be applied to arrays are indeed applied to arrays
        #
        # Needs to handle both array literals as well as variable nodes
        # whose value is an array node.

        if @argument.kind_of? Node_Array then
            return @argument.expressions
        end
        if @argument.is_a? Node_Variable then 
            value = ScopeManager.symbol_lookup(@argument.name)
            if !value.is_a? Array then
                puts message
                return nil
            end
            return value
        end
        puts message
        return nil
    end
    
    def eval
        ##
        # Evaluate the Node based on the value of @name, i.e. the name
        # of the built-in function being called
        #
        # This function handles all the built-in functions, as this node handles
        # all built-in functions. 
        # 
        # This function uses 'case-when' clauses to decide how to evaluat this node
        # based on the desired built-in function.
        # 
        #
        message = "Argument should be an Array.\nGiving you nil.\n"
        
        # Check cases
        case @name

        when "show"
            puts Node_Show.new(@argument).eval

        when "prime"
            if @argument.is_a? Node_Variable then
                value = ScopeManager.symbol_lookup(@argument.name)
                if !value.is_a? Integer then
                    puts "Argument should be an Integer.\n"
                    return false
                end
            else
                value = @argument.val
            end
            
            # Check primality
            # There are faster ways. This was just a simple way to write 
            # it for only checking one value.
            if value < 2 then 
                return false
            end
            (2..(value/2)).each {
                |x| if value % x == 0 then
                        return false    
                    end 
            }
            return true
        
        # built-in array functions
        # These functions check to ensure
        # the operand is an Array or represents an array
        #
        when "empty"
            ##
            # Checks if the array is empty

            result_array_control = array_control(message) 
            if result_array_control then
                result_array_control.size == 0
            else
                # If the result is nil, that is the array equivalent of the empty set.
                true 
            end

        when "size"
            ##
            # Returns the numer of elements in the array

            result_array_control = array_control(message) 
            if result_array_control then
                result_array_control.size
            else
                result_array_control
            end

        when "sort"
            ##
            # Sorts the array using Ruby's sort! function

            result_array_control = array_control(message) 
            if result_array_control then
                if @argument.is_a? Node_Variable then
                    return result_array_control.sort!
                end
                if @argument.kind_of? Node_Array then
                    return result_array_control.map(&:eval).sort!
                end
            else
                return result_array_control
            end

        when "flip"
            ##
            # Reverses the order of array elements using Ruby's reverse! function

            result_array_control = array_control(message) 
            if result_array_control then
                if @argument.is_a? Node_Variable then
                    return result_array_control.reverse!
                end
                if @argument.kind_of? Node_Array then
                    return result_array_control.map(&:eval).reverse!
                end
            else
                return result_array_control
            end

        when "set"
            # Sorts and removes extraneous elements in the Array.
            # Uses Ruby's sort! and uniq functions
            # As we still want an Array and NOT a Ruby Set object, we avoid Ruby .to_set function

            result_array_control = array_control("Argument should be an Array.\nGiving you nil.\n") 
            if result_array_control then 
                if @argument.is_a? Node_Variable then
                    return result_array_control.uniq.sort!
                end
                if @argument.kind_of? Node_Array then
                    return result_array_control.map(&:eval).uniq.sort!
                end
            else
                return result_array_control
            end
        
        when "map"
            ##
            # 'Map' or apply a function to each element of an Array.
            # Only supports single-argument functions

            result_array_control = array_control("Argument should be an Array.\nGiving you nil.\n") 
            array_result_map = []
            if result_array_control then
                if @argument.is_a? Node_Variable then
                    result_array_control.each { |x|
                        # Fill the temporary array with Node_Function_Call nodes
                        array_result_map << Node_Function_Call.new(@function, [Node_Integer.new(x)])
                    }
                end

                # If the array is of type Node_Array then 
                # we must apply the  @function differently.
                # See array_control function above

                if @argument.kind_of? Node_Array then
                    result_array_control.each { |x|
                        array_result_map << Node_Function_Call.new(@function, [x])
                    }
                end
            else
                return result_array_control
            end

            # Return the evaluated new Node_Array
            return Node_Array.new(array_result_map).eval
            
        when "filter"
            ##
            # 'filters' or keeps array elements that fulfill the given 
            # boolean condition passed in as @function

            result_array_control = array_control("Argument should be an Array.\nGiving you nil.\n") 
            array_result_filter = []
            if result_array_control then
                if @argument.is_a? Node_Variable then
                    result_array_control.each { |x|

                        # only add the results that evaluate to 'true' with the given function
                        if Node_Function_Call.new(@function, [Node_Integer.new(x)]).eval then
                            array_result_filter << Node_Integer.new(x)
                        end
                    }
                end

                # Similar to 'map'.
                # See array_control function for differences
                # based on if our array @argument is a Node_Array or Node_Variable whose value is an array.
                if @argument.kind_of? Node_Array then 
                    result_array_control.each { |x|
                        if Node_Function_Call.new(@function, [x]).eval then
                            array_result_filter << x
                        end
                    }
                end
            else
                return result_array_control
            end

            # Return the evaluated new Node_Array
            return Node_Array.new(array_result_filter).eval
        end
    end

end

#
# AST Node for comparison operations

class Node_Comparison
    ##
    # Similar to a Node Arithmetic.
    # This Node has two operatnds and handles
    # operators: <, <=, >, >=, ==, !=
    attr_accessor :lhs, :op, :rhs
    def initialize(lhs, op, rhs)
        ##
        # Bind the nodes on the left hand side, right hand side
        # of the operand to this node, as well as the operand
        #
        @lhs = lhs
        @op = op
        @rhs = rhs
    end

    def eval
        ##
        # Evaluate the left hand child of this node and, using the operand
        # send the result to the right hand side and it's children (if any)
        # Send the result all the way down the AST
        #
        @lhs.eval.send(@op, @rhs.eval)
    end

end

##
# Node to represent a continue statement, which does nothing

class Node_Continue 
    ## 
    # Terminal node, does nothing
    #
    def eval  
        ##
        # empty
        # 
    end
end

#
# AST Node for Doubles

class Node_Double
    ##
    # Node to represent a number that
    # is a Double. Has attribute value only

    attr_accessor :val
    
    def initialize(a)
        ##
        # Terminal node representing a double (decimal) value.
        # Bind the given value to this node
        #
        @val = a.to_f 
    end

    def show
        ##
        # print the value of this node
        #
        p @val
    end

    def eval
        ##
        # Return the value of this node
        #
        @val
    end
end

##
# Node to Handle iteration over all elements of an array

class Node_For_Each
    ##
    # Creates a Node to handle iteration over all elements of an array
    # and execution of code blocks using each element in the array
    # @iterator is the dummy variable for each element
    # @array_expression is the array we iteratore over
    # @body is the block of code to execute for each element in the array

    attr_accessor :iterator, :array_expression, :body

    def initialize(iterator, expression, body)
        ##
        # Bind the 'dummy' variable (@iterator), the expression
        # (Array) to iterate over, and the statement body to be evaluated
        # each iteration to this Node.
        #
        @iterator = iterator
        @array_expression = expression
        @body = body
    end

    def eval 
        ##
        # This function evaluates the body of statements
        # for each iteration (element) in an Array
        # Returns the last-evaluated expression
        # 

        # Push a new symbol table onto the stack
        ScopeManager.stack_frame_create
        
        # Make a Ruby Array of our Node_Array @array_expressions
        array = @array_expression.eval
        
        # Initialize the final result
        result_final = nil

        # break flag init
        break_flag = false
        
        # For each member of the array, evalute the body with the
        # value in the array and save to our result_final.
        array.each {|elem|
            if break_flag then 
                return nil
                #break 
            end
            
            # Store variable with the given value in our symbol table
            ScopeManager.symbol_create(@iterator, elem)
            
            # Evaluate each statement in the block body
            @body.each { |b|
                begin
                    result_final = b.eval
                    if result_final.is_a? Node_Break then 
                        break_flag = true
                        break
                    end

                rescue UndefinedSymbolError
                    puts "Could not find variable.\n"
                    return nil 
                end
            } 
        }
        # When the block is finished, destroy the symbol table
        ScopeManager.stack_frame_destroy
            
        break_flag ? break_flag = false : nil
        # Return the final result
        result_final   
    end
end

##
# Node to handle calling of functions for evaluation

class Node_Function_Call
    ##
    # Attributes consist of a name and the arguments (list)
    # supplied to the function

    attr_accessor :name, :args

    def initialize(name, args)
        ##
        # Bind the function name as well as the arguments (Node_List)
        # to this node
        #
        @name = name
        @args = args
    end

    def eval
        ##
        # Gets the definition of the function(function body) by calling the name
        # in ScopeManager symbol_lookup()
        # Given the arguments initialized with this node, and the fetched function 
        # body, evaluate each expression in the body with the given arguments
        # Returns the last evaluated expression
        #

        # Create a new scope for the function body
        ScopeManager.stack_frame_create
        
        # Get the function definition from our stack of symbol tables
        func_def = ScopeManager.symbol_lookup(@name)

        # if arguments supplied
        if args then 
            arg_values = @args.map(&:eval)
        
            # Bind the arguments to their symbols
            func_def.arg_list.each_with_index do |arg, i|
                ScopeManager.symbol_create(arg, arg_values[i])
            end
        end

        result = nil

        # Evaluate the function
        func_def.body.each do |node| 
            result = node.eval
        end
        
        # Kill the current scope
        ScopeManager.stack_frame_destroy

        return result
    end

end

##
# Node the represents the definition of a function

class Node_Function_Define
    ##
    # This class defines the function and stores it to be called at another time

    attr_accessor :name, :arg_list, :body

    def initialize(name, args, body)
        ##
        # Bind the function name, the arguments, and the body to this node
        #
        @name = name
        @arg_list = args
        @body = body     
    end

    def eval
        ##
        # This node evaluates by sending the function definition to ScopeManager
        # returns nil
        #

        # Store the name and the Node_Function_Define object
        # in the ScopeManager. The function will be evaluated by a Node_Function_Call

        ScopeManager.function_define(@name, self)
    end
end

## AST Node for If-statements
#

class Node_If
    ##
    # This node has two or three children where @condition is the child node to be evaluated
    # @then_block is evaluated if @condition evaluates to true otherwise the @else_block is evaluated
    # @else_block can very well be nil

    attr_accessor :condition, :then_block, :else_block
    
    def initialize(cond, then_, else_)
        ##
        # Binds the children to this node, which are a boolean condition,
        # a then block and (possibly) an else block
        #
        @condition = cond
        @then_block = then_
        @else_block = else_
    end 

    def eval
        ##
        # This function first evalutes the condition. It only evaluates the 
        # then-block child if @condition evalutes to true, otherwise it evaluates
        # the else-child block (if it exists)
        # Returns the last evaluated statement in whichever block was evaluated
        # 

        #
        # Evaluate the condition 
        condition_val = @condition.eval

        # Push a new scope onto the stack
        ScopeManager.stack_frame_create

        # initialize final result
        last_result = nil

        # Evaluate the appropriate block
        if condition_val then
            @then_block.each {|x| last_result = x.eval}
        elsif @else_block then
            @else_block.each {|x| last_result = x.eval}
        end

        # Pop the current scope
        ScopeManager.stack_frame_destroy

        # Return the value of the last statement executed in the block
        last_result
    end
end

#
# AST Node for Integers

class Node_Integer 
    ##
    # An Integer is a terminal node with its only attribute the value of the integer

    attr_accessor :val
    def initialize(val)
        ##
        # Terminal node. Has only a value.
        @val = val
    end

    def show
        ##
        # Print the value of this node
        #
        p val
    end

    def eval
        ##
        # Returns the value of this node
        #
        @val
    end
end

#
# AST Node to represent lists of expressions, lists of arguments, etc. 
# *NOT* to be confused with Node_Array, which represents an Array datatype in
# Whisper.

class Node_List < Array 
    #
    # Think of a list as in a list of expressions like: (expression, expression_list)
    # so we can recursively evaluate every expression in a list of
    # expressions

    def initialize(explist)
        ##
        # Bind the list of expressions (function arguments, list of expressions in a code block)
        # to this node.
        #
        explist.each {|x| self << x }
    end

    def eval
        ##
        # The result is the accumulation of evaluating all expression-children
        # of this node.
        # Returns a call to eval the result
        #

        # Evaluate each expression or argument in the list and accumulate the result
        # Behaves like a 'folding' function

        result = self.inject {|f| f.eval }     
        
        # After accumulating over the list, evaluate the final result and return
        result.eval
    end

    def show
        ##
        # Print each expression in this 
        #
        self.each {|elem| puts elem}
    end

end

#
# AST Node for Boolean operations 

class Node_Logical_Op
    ##
    # Node to handle expressions involving &&, ||, !

    attr_accessor :lhs, :op, :rhs
    def initialize(lhs, op, rhs)
        ##
        # Bind the two children (logical expressions)
        # and the logical operation to this node
        #
        @lhs = lhs
        @op = op
        @rhs = rhs
    end

    def show
        ##
        # print the node and its children
        #
        p "#{lhs.to_s}, #{op.to_s}, #{rhs.to_s}"
    end

    def eval
        ##
        # Evaluate one or both children depending on the operand
        # that is @op
        # Returns a call to evaluate the appropriate child based on @op
        #
        rval = @rhs.eval

        # lhs is nil when NOT operator is used
        # therefore, don't evalute lhs in that case
        if @lhs != nil then
          lval = @lhs.eval
        end
        
        if @op == "&&" then
            @op = "&"
        end

        if @op == "||" then
            @op = "|"
        end

        # Do standard eval and send unless NOT is used
        # In that case, just return the inverse of what rhs evaluates to
        if @lhs != nil
            @lhs.eval.send(@op, @rhs.eval)
        else
            !@rhs.eval
        end
    end
end

##
# AST Node for operations involving variable reassignemnt

class Node_Reassign 
    ##
    # For already declared variables, apply the operations
    # '+=', '-=', '/=', or '*=' to the @variable_name

    attr_accessor :op, :variable_name, :value

    def initialize(op, name, val) 
        ##
        # Bind the operation, the variable name, and the value to adjust
        # the current value by
        #
        @op = op
        @variable_name = name.name
        @value = val
    end

    def eval 
        ##
        # Evaluate the right hand side of the equation, i.e. that which 
        # we wish to add, subtract, divide or multiply the original variable by
        # Returns the updated value
        #

        rhs = @value.eval

        # lookup the current value
        current_value = ScopeManager.symbol_lookup(@variable_name)

        result = case @op
        when "+="
            current_value + rhs
        when "-="
            current_value - rhs
        when "/="
            current_value / rhs
        when "*="
            current_value * rhs
        end

        # After calculating the new value, update the symbol table.
        ScopeManager.symbol_update(@variable_name, result)

        result
    end

end

##
# AST Node to represent a Record data type

class Node_Record
    ##
    # A Record is an associative container, like a Hash
    # This node has one attribute, @fields, which holds variables
    # and their associated values. 
    #
    # Records are very limited as of 25/5/2023 and the authors are aware of this.
    # They simply hold a simple hash-like structure of values

    attr_accessor :fields

    def initialize(fields)
        ##
        # Bind the data fields (like a struct)
        # to this node
        #
        @fields = fields
    end

    def eval
        ##
        # Convert the nested arrays matched in the parser to a Hash
        # of pairs
        # Returns a Hash resembling {"variable"=>value, ... }

        @fields.to_h.transform_values! { |node_value| 
            if node_value.is_a? Array then
                node_value.to_h.transform_values! { |v| v.eval }
            else
                node_value.eval
            end 
        }
    end

end

##
# AST Node to handle lookups in Records

class Node_Record_Access 
    ## 
    # In order to lookup a value in a Record, we need
    # the record name and the name of the field (value) we are looking for

    attr_accessor :record_name, :field_name

    def initialize(record_name, field_name)
        ##
        # Bind the name of the record and the name of the desired field
        # to this node
        #
        @record_name = record_name
        @field_name = field_name
    end

    def eval
        ##
        # If the Record in question is nested, (contains a record)
        # then we must first evaluate the nested Record to get a Hash

        if @record_name.is_a? Node_Record_Access then
            record = @record_name.eval
        else
            # get the value of the given Record from the ScopeManager

            record = ScopeManager.symbol_lookup(@record_name)
        end
        # Return the value of the given field in the Record
        return record[@field_name]

    end
end

##
# AST Node to handle the show function
class Node_Show
    ##
    # This Node prints the value of a given variable
    attr_accessor :arg, :int
    
    def initialize(arg, int=nil) 
        ##
        # Bind the argument and if it is a simple integer, the value
        # to this node
        #
        @arg = arg
        @int = int
    end

    def eval
        ##
        # If this is an integer, return a string of the value
        # of this integer
        #
        # If it is a Node, return a string of the evaluation of this node
        #
        if int then
            return "#{@arg}"
        end
        return "#{@arg.eval}"
    end

end

##
# AST Node for a Variable

class Node_Variable
    ##
    # A Variable node holds a name. It is often
    # used as the 'left hand side' of an Assignment, i.e. 'a' = 7

    attr_accessor :name

    def initialize(name)
        ##
        # Terminal node that represents a variable name
        # Bind the name to this node
        #
        @name = name
    end

    def to_s
        ##
        # Get a string representation of the variable name. Handy for doing lookups.
        #
        @name.to_s
    end

    def show 
        ##
        # Print an evaluate of this (the name)
        #
        p self.eval
    end

    def eval
        ##
        # Returns a call to ScopeManager, which looks up the node
        # that is represented by this variable name
        #

        # lookup the value of this variable which will either return 
        # the value or nil if not found
        ScopeManager.symbol_lookup(@name)
    end
end

##
# AST Node for While-loops

class Node_While 
    ##
    # This node represents a while loop and has attributes @condition and @block
    # where so long as @condition is true, @block is evaluated

    attr_accessor :condition, :block

    def initialize(condition, block) 
        ##
        # Bind the boolean condition and
        # code block child-nodes to this node
        #
        @condition = condition
        @block = block
    end

    def eval
        ##
        # While the condition holds, evaulate the block of expressions or statments
        # Return the final evaluated result
        #

        # Because a while-loop contains a block of code, create a new scope
        ScopeManager.stack_frame_create

        # initialize result and break-statement flag
        last_result = nil
        break_flag = false

        # Evaluate the block while the @condition evaluates to true
        while @condition.eval
            if break_flag
                break
            end

            # evaluate each statement in the block, checking if 'break' is encountered
            @block.each { |x|
                last_result = x.eval
                if last_result.is_a? Node_Break then
                    break_flag = true
                    break
                end
            }
        end

        # Reset break flag
        break_flag ? break_flag = false : nil 
        
        # Destroy current symbol table
        ScopeManager.stack_frame_destroy
        
        # Return the final result
        if last_result.is_a? Node_Break then
            return nil
        else
            last_result
        end
    end

end
