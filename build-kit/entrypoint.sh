#!/bin/sh

setup_cache(){
    export CPM_SOURCE_CACHE=$EXT_MOUNT/cache/cpm
    export CCACHE_DIR=$EXT_MOUNT/cache/ccache

    maven_cache_dir=$EXT_MOUNT/cache/m2-repo

    # we copy the settings file each time in case the $HOME folder changes
    mkdir -p $HOME/.m2 || true
    cp $ASSETS_PATH/maven-settings.xml $HOME/.m2/settings.xml
    sed -i 's@MAVEN_CACHE_REPOSITORY@'"$maven_cache_dir"'@' $HOME/.m2/settings.xml
}

# if first cmd is exec we're going to exec what follows
# otherwise check for script
run_script(){

    if [ "$1" = 'run-script' ]; then

        if [ -z "$2" ]; then
            echo "Error: missing script name for run-script mode"
            exit 1
        fi

        init_script=$EXT_MOUNT/scripts/$2.sh

        if [ ! -f "$init_script" ]; then
            echo "Error: no script found at $init_script"
            # bash convention, 127 = not found
            exit 127
        fi

        exec $init_script
    fi

    # not the run-script mode
    exec "$@"

}

setup_cache
run_script $@

