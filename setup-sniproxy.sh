#!/bin/bash

echo "# Patch SNIProxy config and service"

# Ensure sniproxy is installed (some fresh VMs won't have it yet).
if ! command -v sniproxy >/dev/null 2>&1; then
  echo "- Installing sniproxy package..."
  sudo apt-get update
  # Avoid interactive prompts on conffiles (/etc/default/sniproxy).
  sudo DEBIAN_FRONTEND=noninteractive \
    apt-get install -y \
    -o Dpkg::Options::="--force-confdef" \
    -o Dpkg::Options::="--force-confold" \
    sniproxy
fi

sudo mkdir -p /etc/systemd/system/sniproxy.service.d

cp ./sniproxy.conf.example /etc/sniproxy.conf

# Debian's sniproxy systemd unit doesn't reference $DAEMON_ARGS, so we must
# explicitly pass the config path.
cat >/etc/systemd/system/sniproxy.service.d/override.conf <<'EOF'
[Service]
ExecStart=
ExecStart=/usr/sbin/sniproxy -c /etc/sniproxy.conf
EOF

sudo systemctl daemon-reload
sudo systemctl restart sniproxy
sudo systemctl enable --now sniproxy

/usr/sbin/rndc flush

echo "- Check listener sockets:"
sudo ss -ulpn | grep -E ':80\\b|:443\\b' || true
