# Authors: Viktor Norlin & Warren Crutcher

##
# ScopeManager is how we handle scoping in the Whisper language
# ScopeManager functions as a "stack of symbol tables"
# where a "symbol table" is a more descriptive way of saying "Hash"
# as the symbol table holds the values of symbols (variable names, function names, etc)
# and the Array that holds these symbol tables (Hashes) functions like a Stack, 
# that is the First in, First out.
#
# Each 'level' of scoping is a Hash in the stack where these hashes are pushed and popped
# onto or from the stack as new blocks of code are encountered.
# 
# During symbol lookup, the current scope (top of the stack) is always where the value is first
# searched. It is also the level where all values declared in the current scope reside.
# If a symbol is not found in the current scope, we look in the nest 'lowest' scope down the stack
# and continue until we either find the value or return nil
#

class ScopeManager
    ##
    # We implement ScopeManager as a static instance. We only want one ScopeManager
    # while running Whisper

    # Initialize the scope class variable as an array with an empty hash (the global scope)
    @@scope = [{}]

    def self.stack_frame_create
        ##
        # Push a new table onto the stack

        @@scope << Hash.new
    end

    def self.stack_frame_destroy
        ## 
        # Remove the current scope from the stack
        @@scope.pop
    end

    # If the symbol is found as a key in any scope, return the value
    # If the symbol is not found, return nil
    def self.symbol_lookup(sym)
        ##
        # Arguments: variable name (sym)
        #
        # Returns: if the symbol is found, return the node associated with the symbol
        # otherwise return an UndefinedSyumbolError object
        #
        sym = sym.to_sym
        @@scope.reverse_each {|x|
            if x[sym] != nil
                return x[sym]
            end
        }

        # Symbol not found
        return UndefinedSymbolError.new(sym)
    end

    def self.function_define(name, definition)
        ##
        # Same functionality as symbol_create. 
        # However, even with mirrored functionality
        # it can be nice to sperate functions from variables

        @@scope[-1][name.to_sym] = definition
        
    end

    def self.symbol_create(sym, val)
        ##
        # Add a new symbol and value to the current scope
        # Always happens at the top of the stack

        @@scope[-1][sym.to_sym] = val
    end

    # Function that prints all scopes for debugging purposes
    def self.scope_print()
        ##
        # Print the stack of scopes
        #
        p @@scope
    end

    # Function to change an existing value without without making a new assignment
    def self.symbol_update(sym, val_new)
        ##
        #
        
        # Convert the given variable to a Ruby symbol
        sym = sym.to_sym

        # Change the value if we find it
        if self.symbol_lookup(sym) then
            @@scope.reverse_each { |x|
                if x[sym] != nil
                    x[sym] = val_new
                end
            }
        else
            # If we don't find it, raise error, i.e. we cannot update a value for a symbol that does not exist.
            raise NameError, "Undefined local symbol: #{sym.to_s}\n"
        end
    end
end

##
# Class to print a message for trying to use an undefined variable
class UndefinedSymbolError < StandardError 
    
    def initialize(variable) 
        ##
        # Functions as a 'nil' object but prints
        # helpful message to the console if trying to access
        # a variable that is undeclared
        #
        puts "Undeclared Variable #{variable}"
    end
end