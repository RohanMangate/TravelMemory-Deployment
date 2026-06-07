#!/bin/bash
# Deploy DB script via WSL with SSH config
KEY=/tmp/travelmemory-key.pem
WEB_IP=43.205.237.130
DB_IP=10.0.2.161

# Copy key
cp /mnt/c/Users/RohanVijayMangate/Documents/TravelMemory-Deployment/terraform/travelmemory-key.pem $KEY
chmod 600 $KEY

# Create SSH config
cat > /tmp/ssh_config << SSHEOF
Host web
    HostName ${WEB_IP}
    User ubuntu
    IdentityFile ${KEY}
    StrictHostKeyChecking no

Host db
    HostName ${DB_IP}
    User ubuntu
    IdentityFile ${KEY}
    StrictHostKeyChecking no
    ProxyJump web
SSHEOF

# Create inventory using SSH config aliases
cat > /tmp/inventory.ini << INVEOF
[webserver]
web ansible_host=web ansible_user=ubuntu

[dbserver]
db ansible_host=db ansible_user=ubuntu

[all:vars]
ansible_python_interpreter=/usr/bin/python3
INVEOF

echo "=== Testing SSH to DB via jump ==="
ssh -F /tmp/ssh_config db "echo 'DB server reachable!'"

echo ""
echo "=== Running DB Playbook ==="
cd /mnt/c/Users/RohanVijayMangate/Documents/TravelMemory-Deployment/ansible
ANSIBLE_HOST_KEY_CHECKING=False ANSIBLE_SSH_ARGS="-F /tmp/ssh_config" ansible-playbook -i /tmp/inventory.ini playbook-db.yml -v
