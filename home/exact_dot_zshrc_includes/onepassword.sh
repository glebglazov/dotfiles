op-signin() {
  account_shorthand=$1
  token=$(op signin --account $account_id --raw)
  account_id=$(op account get | grep "ID" | awk '{print $2}')

  export "OP_SESSION_$account_id"=$token
}
