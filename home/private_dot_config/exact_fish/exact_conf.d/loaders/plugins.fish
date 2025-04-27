for plugin_dir in $__fish_config_dir/plugins/*
    if test -d $plugin_dir
        set -l init_file $plugin_dir/init.fish
        if test -f $init_file
            source $init_file
        else
            # Add plugin's functions directory to fish_function_path
            if test -d $plugin_dir/functions
                set fish_function_path $fish_function_path $plugin_dir/functions
            end

            # Source all .fish files in the plugin
            for f in $plugin_dir/**/*.fish
                source $f
            end
        end
    end
end
