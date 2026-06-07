# TravelMemory MERN Application - AWS Deployment

Deploying the [TravelMemory](https://github.com/UnpredictablePrashant/TravelMemory) MERN application on AWS using Terraform and Ansible.

---

## Prerequisites

Before starting, ensure you have:

1. **AWS Account** with programmatic access (Access Key + Secret Key)
2. **AWS CLI** installed and configured
3. **Terraform** (v1.0+) installed
4. **Ansible** (v2.9+) installed (use WSL/Linux - Ansible doesn't run natively on Windows)
5. **Git** installed

---

## Step-by-Step Deployment Guide

### STEP 1: Install Required Tools

```bash
# Install AWS CLI (if not already installed)
# Download from: https://aws.amazon.com/cli/

# Verify AWS CLI
aws --version

# Install Terraform
# Download from: https://developer.hashicorp.com/terraform/downloads
terraform --version

# For Ansible, use WSL (Windows Subsystem for Linux) or a Linux machine
# In WSL/Ubuntu:
sudo apt update
sudo apt install -y ansible python3-pip
pip3 install pymongo
ansible-galaxy collection install community.mongodb
```

### STEP 2: Configure AWS CLI

```bash
aws configure
# Enter your:
#   AWS Access Key ID
#   AWS Secret Access Key
#   Default region: ap-south-1
#   Default output format: json

# Verify credentials
aws sts get-caller-identity
```

### STEP 3: Find Your Public IP

Go to https://whatismyip.com and note your public IP address. You'll need it for Step 4.

### STEP 4: Update Terraform Variables

Edit `terraform/terraform.tfvars`:

```hcl
aws_region = "ap-south-1"
my_ip      = "YOUR_ACTUAL_IP/32"    # e.g., "203.0.113.50/32"
ami_id     = "ami-0f5ee92e2d63afc18" # Ubuntu 22.04 in ap-south-1
```

> **Note:** If the AMI ID is outdated, find the latest Ubuntu 22.04 AMI:
> ```bash
> aws ec2 describe-images --owners 099720109477 --filters "Name=name,Values=ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*" --query 'Images | sort_by(@, &CreationDate) | [-1].ImageId' --output text --region ap-south-1
> ```

### STEP 5: Deploy Infrastructure with Terraform

```bash
cd terraform/

# Initialize Terraform
terraform init

# Preview changes
terraform plan

# Apply (type 'yes' when prompted)
terraform apply

# Note the outputs:
#   web_server_public_ip
#   db_server_private_ip
#   ssh_key_file path
```

**Save the output values** - you'll need them for Ansible.

### STEP 6: Update Ansible Inventory

Edit `ansible/inventory.ini` and replace placeholders with actual IPs from Terraform output:

```ini
[webserver]
web ansible_host=<WEB_SERVER_PUBLIC_IP> ansible_user=ubuntu ansible_ssh_private_key_file=../terraform/travelmemory-key.pem

[dbserver]
db ansible_host=<DB_SERVER_PRIVATE_IP> ansible_user=ubuntu ansible_ssh_private_key_file=../terraform/travelmemory-key.pem ansible_ssh_common_args='-o ProxyJump=ubuntu@<WEB_SERVER_PUBLIC_IP>'
```

### STEP 7: Update Web Server Playbook

Edit `ansible/playbook-web.yml` and replace `<DB_SERVER_PRIVATE_IP>` in the `vars` section with the actual private IP from Terraform output.

### STEP 8: Wait for EC2 Instances to Initialize

Wait 2-3 minutes for instances to boot and become SSH-ready.

```bash
# Test SSH connection to web server
ssh -i terraform/travelmemory-key.pem ubuntu@<WEB_SERVER_PUBLIC_IP>

# Test SSH to DB server via jump host
ssh -i terraform/travelmemory-key.pem -J ubuntu@<WEB_SERVER_PUBLIC_IP> ubuntu@<DB_SERVER_PRIVATE_IP>
```

### STEP 9: Run Ansible Playbooks

```bash
cd ansible/

# Run database server setup first
ansible-playbook playbook-db.yml

# Then run web server setup
ansible-playbook playbook-web.yml

# OR run both together:
# ansible-playbook site.yml
```

### STEP 10: Verify Deployment

```bash
# Check backend API
curl http://<WEB_SERVER_PUBLIC_IP>:3001/tripdetails

# Open in browser
# Frontend: http://<WEB_SERVER_PUBLIC_IP>
# Backend API: http://<WEB_SERVER_PUBLIC_IP>:3001/tripdetails
```

### STEP 11: Take Screenshots

Capture screenshots of:
1. `terraform apply` output
2. `ansible-playbook` execution output
3. Application running in browser (frontend)
4. API response (backend)
5. AWS Console -> EC2 instances
6. AWS Console -> VPC/Subnets

Save in the `screenshots/` folder.

---

## Cleanup (After Assignment Submission)

```bash
cd terraform/
terraform destroy
# Type 'yes' to confirm
```

**Important:** Always destroy resources after you're done to avoid AWS charges!

---

## Project Structure

```
TravelMemory-Deployment/
├── terraform/
│   ├── provider.tf          # AWS provider configuration
│   ├── variables.tf         # Input variables
│   ├── terraform.tfvars     # Variable values (edit this)
│   ├── vpc.tf               # VPC, subnets, gateways, route tables
│   ├── security_groups.tf   # Security groups for web and DB
│   ├── iam.tf               # IAM roles and policies
│   ├── ec2.tf               # EC2 instances and key pair
│   └── outputs.tf           # Output values (IPs, DNS)
├── ansible/
│   ├── ansible.cfg          # Ansible configuration
│   ├── inventory.ini        # Host inventory (edit this)
│   ├── site.yml             # Master playbook
│   ├── playbook-db.yml      # Database server playbook
│   ├── playbook-web.yml     # Web server playbook
│   └── roles/
│       ├── dbserver/templates/
│       │   └── mongod.conf.j2
│       └── webserver/templates/
│           └── nginx.conf.j2
├── screenshots/             # Deployment screenshots
├── REPORT.md                # Detailed deployment report
└── README.md                # This file
```

---

## Troubleshooting

| Issue | Solution |
|-------|----------|
| SSH connection timeout | Wait 2-3 min after `terraform apply`; check security group allows your IP |
| Ansible can't reach DB server | Ensure ProxyJump is configured in inventory; check NAT gateway is working |
| MongoDB connection refused | Check mongod.conf binds to 0.0.0.0; check DB security group allows port 27017 from web SG |
| Frontend shows blank page | Check `REACT_APP_BACKEND_URL` in frontend .env; rebuild frontend |
| Backend crashes | Check `.env` has correct MONGO_URI; verify MongoDB is running on DB server |
| AMI not found | Find latest Ubuntu 22.04 AMI for your region (see Step 4 note) |

---
