op-signin() {
  account_shorthand=$1
  user_id=$(op account list | grep $account_shorthand | awk '{print $4}')

  token=$(op signin --account $user_id --raw)
  export "OP_SESSION_$user_id"=$token

  account_id=$(op account get | grep "ID" | awk '{print $2}')
  export "OP_SESSION_$account_id"=$token
}
