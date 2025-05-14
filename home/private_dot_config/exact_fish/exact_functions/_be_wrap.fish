function _be_wrap
    if _find_file_in_pwd_recursively
        be $argv
    else
        eval $argv
    end
end
