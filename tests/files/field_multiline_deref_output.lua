if true then
    vim
        .api
        .nvim_buf_set_text(vim._create_ts_parser("vim"))
        .do_more(assert(111).assert_more(222 + 111))
end

