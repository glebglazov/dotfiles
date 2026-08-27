function _be_wrap {
    if _find_file_in_pwd_recursively Gemfile; then
        _op_run bundle exec "$@"
    else
        _op_run "$@"
    fi
}
