function op-signin
    set account_shorthand $argv[1]
    set user_id (op account list | grep $account_shorthand | awk '{print $4}')

    set token (op signin --account $user_id --raw)
    set -gx "OP_SESSION_$user_id" $token

    set account_id (op account get | grep "ID" | awk '{print $2}')
    set -gx "OP_SESSION_$account_id" $token
end
