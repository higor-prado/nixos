{
  directories = [
    "/etc/NetworkManager/system-connections"
    "/var/lib/bluetooth"
    "/var/lib/tailscale"
    "/var/lib/docker"
    "/var/lib/containers/storage"
    "/var/lib/nixos"
    "/var/lib/dms-greeter"
  ];

  files = [
    "/etc/machine-id"
    "/etc/ssh/ssh_host_ed25519_key"
    "/etc/ssh/ssh_host_ed25519_key.pub"
    "/etc/ssh/ssh_host_rsa_key"
    "/etc/ssh/ssh_host_rsa_key.pub"
    "/etc/ssh/ssh_host_ecdsa_key"
    "/etc/ssh/ssh_host_ecdsa_key.pub"
    "/var/lib/systemd/random-seed"
  ];

  # Candidate paths intentionally ignored for now.
  # Keep rationale in comments next to each path when needed.
  ignored = [
    "/root" # root is not used as a working environment on this host
  ];
}
