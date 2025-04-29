function _cd-to-aws-envrc
    if set -q AWS_ENVRC_PATH
        cd $AWS_ENVRC_PATH
        direnv reload
    end
end
