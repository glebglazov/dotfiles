function aws
    begin
        __aws_envrc_path_cd
        command aws $argv
    end
end
