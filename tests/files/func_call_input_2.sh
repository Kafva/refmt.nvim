build() {
    cmake -B build -S src -Wno-dev -DCMAKE_POLICY_VERSION_MINIMUM=3.5 -DCMAKE_BUILD_TYPE='Release' -G Ninja
}

