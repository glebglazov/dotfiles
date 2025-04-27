function __aws_envrc_path_cd
    if set -q AWS_ENVRC_PATH
        cd $AWS_ENVRC_PATH
    end
end
