out/host/linux-x86/bin/lpmake \
    --device-size=auto \
    --metadata-slots=2 \
    --metadata-size=65536 \
    --sparse \
    --partition=system_a:readonly:0:default \
    --image=system_a=out/soong/.intermediates/packages/modules/Virtualization/build/microdroid/microdroid_super/android_arm64_armv8-a/system_a.img \
    --output=out/soong/.intermediates/packages/modules/Virtualization/build/microdroid/microdroid_super/android_arm64_armv8-a/microdroid_super.img
