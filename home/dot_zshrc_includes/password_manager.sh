function get_password {
	bw list items --search $1 | jq -r '.[].login.password'
}

function get_custom_field {
	bw list items --search $1 | jq -r ".[].fields | map(select(.name | contains(\"$2\"))) | .[].value"
}
