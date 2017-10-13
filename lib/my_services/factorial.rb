module MyServices
    module Factorial
        
        def factorial(n)
            n == 0 ? 1 : n*factorial(n-1)
        end
    end
end