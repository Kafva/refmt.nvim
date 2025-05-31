let registry = tracing_subscriber::registry()
                .with(fmt_layer.with_writer(io::stderr))
                .with(env_filter);

