subprocess.run(["supervise-daemon", "dnscrypt-proxy", "--start", "--pidfile", "/run/dnscrypt-proxy.pid", "--respawn-delay", "2", "--respawn-max", "5", "--respawn-period", "1800", "--capabilities", "^cap_net_bind_service", "--user", "root", "root", "/usr/bin/dnscrypt-proxy", "--", "-config", "/etc/dnscrypt-proxy/dnscrypt-proxy.toml"])

if __name__ == '__main__':
    subprocess.run(["supervise-daemon", "dnscrypt-proxy", "--start", "--pidfile", "/run/dnscrypt-proxy.pid", "--respawn-delay", "2", "--respawn-max", "5", "--respawn-period", "1800", "--capabilities", "^cap_net_bind_service", "--user", "root", "root", "/usr/bin/dnscrypt-proxy", "--", "-config", "/etc/dnscrypt-proxy/dnscrypt-proxy.toml"])


dbus-broker --log 4 --controller 9 --machine-id aa317cce739a470da42aec8a75d8df42 --max-bytes 536870912 --max-fds 4096 --max-matches 131072 --audit
