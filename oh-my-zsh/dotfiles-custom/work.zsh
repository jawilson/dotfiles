if [ "$(uname -s)" = "Linux" ]; then
    export MEDIASOUP_ANNOUNCED_IP=$(hostname -I|cut -d' ' -f1)
fi

GSTREAMER_ROOT=/opt/gstreamer
if [ -d $GSTREAMER_ROOT ]; then
    export PATH=$GSTREAMER_ROOT/bin:$PATH
    export PKG_CONFIG_PATH=$GSTREAMER_ROOT/lib/x86_64-linux-gnu/pkgconfig${PKG_CONFIG_PATH:+:$PKG_CONFIG_PATH}
    export C_INCLUDE_PATH=$GSTREAMER_ROOT/include:$GSTREAMER_ROOT/include/gstreamer-1.0${C_INCLUDE_PATH:+:$C_INCLUDE_PATH}
    export CPLUS_INCLUDE_PATH=$GSTREAMER_ROOT/include:$GSTREAMER_ROOT/include/gstreamer-1.0${CPLUS_INCLUDE_PATH:+:$CPLUS_INCLUDE_PATH}
fi

gst_build_dir="$HOME/src/gst-build"
if [ -d $gst_build_dir ]; then
    export PATH=${gst_build_dir}/subprojects/gstreamer/tools:$PATH
    export PATH=${gst_build_dir}/subprojects/gst-plugins-bad/tools:$PATH
fi
