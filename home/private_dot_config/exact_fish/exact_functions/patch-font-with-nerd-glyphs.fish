# there should be two folders: input and patched
#
# input should contain the font files (*.ttf) to be patched
#
#
function patch-font-with-nerd-glyphs
    docker run --rm \
        -v $(PWD)/input:/in:Z \
        -v $(PWD)/patched:/out:Z \
        -e "PN=10" nerdfonts/patcher \
        --careful
end
