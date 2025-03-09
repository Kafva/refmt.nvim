def generate_keys(hosts: [Host], out: str):
    for host in filter(lambda h: not h.remote_only, hosts):
        name_dir = f"{out}/{host.name}"
        key = f"{name_dir}/id_rsa"
        os.makedirs(name_dir, exist_ok=True)

        if os.path.isfile(key):
            continue

        run([
            "ssh-keygen",
            "-t",
            "rsa",
            "-b",
            "2048",
            "-C",
            host.name,
            "-f",
            key,
            "-N",
            "",
        ])

