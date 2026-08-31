function __be_wrap {
    if __find_file_in_pwd_recursively Gemfile; then
        __op_run bundle exec "$@"
    else
        __op_run "$@"
    fi
}
