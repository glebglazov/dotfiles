function _be_wrap
    if _find_file_in_pwd_recursively Gemfile
        be $argv
    else
        eval $argv
    end
end
