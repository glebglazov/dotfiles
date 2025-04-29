function k --wraps kubectl
    _execute-with-aws-envrc command kubectl $argv
end
