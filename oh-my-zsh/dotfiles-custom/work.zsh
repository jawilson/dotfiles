if [ "$(uname -s)" != "Darwin" ]; then
    export MEDIASOUP_ANNOUNCED_IP=$(hostname -I|cut -d' ' -f1)
fi

if [ -d /opt/gstreamer ]; then
    export PATH=/opt/gstreamer/bin:$PATH
    export PKG_CONFIG_PATH=/opt/gstreamer/lib/x86_64-linux-gnu/pkgconfig:$PKG_CONFIG_PATH
fi

gst_build_dir="$HOME/src/gst-build"
if [ -d $gst_build_dir ]; then
    export PATH=${gst_build_dir}/subprojects/gstreamer/tools:$PATH
    export PATH=${gst_build_dir}/subprojects/gst-plugins-bad/tools:$PATH
fi
