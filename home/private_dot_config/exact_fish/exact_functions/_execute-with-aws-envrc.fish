function _execute-with-aws-envrc
    fish -i -l -c "_cd-to-aws-envrc; eval \"\$argv\"" -- $argv
end
