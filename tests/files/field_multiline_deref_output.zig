const content_size = try fbs
    .more
    .reader()
    .wow(1)
    .readInt(u32, .little);
