function foo() {
    return makeEven(document
        .documentElement
        .querySelector('#myid')
        .computedStyleMap()
        .clientWidth())
}

