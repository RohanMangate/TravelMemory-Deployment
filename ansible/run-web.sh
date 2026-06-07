#!/bin/bash
set -e

# Variables
WEB_IP="43.205.237.130"
DB_IP="10.0.2.161"
KEY="/tmp/travelmemory-key.pem"
WIN_KEY="/mnt/c/Users/RohanVijayMangate/Documents/TravelMemory-Deployment/terraform/travelmemory-key.pem"

# Copy key to Linux filesystem for proper permissions
cp "$WIN_KEY" "$KEY"
chmod 600 "$KEY"

# Create SSH config
cat > /tmp/ssh_config << EOF
Host web
    HostName ${WEB_IP}
    User ubuntu
    IdentityFile ${KEY}
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null

Host db
    HostName ${DB_IP}
    User ubuntu
    IdentityFile ${KEY}
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null
    ProxyJump web
EOF
chmod 600 /tmp/ssh_config

# Create inventory using SSH config aliases
cat > /tmp/inventory.ini << INVEOF
[webserver]
web ansible_host=web ansible_user=ubuntu

[dbserver]
db ansible_host=db ansible_user=ubuntu

[all:vars]
ansible_python_interpreter=/usr/bin/python3
INVEOF

echo "=== Running Web Server Playbook ==="
cd /mnt/c/Users/RohanVijayMangate/Documents/TravelMemory-Deployment/ansible
ANSIBLE_HOST_KEY_CHECKING=False ANSIBLE_SSH_ARGS="-F /tmp/ssh_config" ansible-playbook -i /tmp/inventory.ini playbook-web.yml -v
