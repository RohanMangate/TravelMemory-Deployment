# Deployment Report: TravelMemory MERN Application on AWS

## 1. Project Overview

This report documents the deployment of the **TravelMemory** MERN (MongoDB, Express.js, React, Node.js) stack application on AWS infrastructure using **Terraform** for infrastructure provisioning and **Ansible** for configuration management and application deployment.

**Application Repository:** https://github.com/UnpredictablePrashant/TravelMemory

---

## 2. Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                         AWS VPC (10.0.0.0/16)                    │
│                                                                   │
│  ┌─────────────────────────────┐  ┌────────────────────────────┐ │
│  │    Public Subnet             │  │    Private Subnet           │ │
│  │    (10.0.1.0/24)            │  │    (10.0.2.0/24)           │ │
│  │                             │  │                            │ │
│  │  ┌───────────────────────┐  │  │  ┌──────────────────────┐ │ │
│  │  │   Web Server (EC2)    │  │  │  │  DB Server (EC2)     │ │ │
│  │  │                       │  │  │  │                      │ │ │
│  │  │  - Nginx (Port 80)    │  │  │  │  - MongoDB (27017)   │ │ │
│  │  │  - Node.js Backend    │──┼──┼──│                      │ │ │
│  │  │    (Port 3001)        │  │  │  │                      │ │ │
│  │  │  - React Frontend     │  │  │  │                      │ │ │
│  │  │    (Static Build)     │  │  │  │                      │ │ │
│  │  └───────────────────────┘  │  │  └──────────────────────┘ │ │
│  │           │                  │  │           │               │ │
│  └───────────┼──────────────────┘  └───────────┼───────────────┘ │
│              │                                  │                  │
│  ┌───────────┴──────┐              ┌───────────┴──────┐          │
│  │  Internet Gateway │              │   NAT Gateway    │          │
│  └───────────┬──────┘              └──────────────────┘          │
└──────────────┼───────────────────────────────────────────────────┘
               │
          ┌────┴────┐
          │ Internet │
          └─────────┘
```

---

## 3. Infrastructure Components (Terraform)

### 3.1 VPC and Networking
| Component | Details |
|-----------|---------|
| VPC | 10.0.0.0/16 with DNS support enabled |
| Public Subnet | 10.0.1.0/24 (ap-south-1a) - Auto-assigns public IPs |
| Private Subnet | 10.0.2.0/24 (ap-south-1a) - No public access |
| Internet Gateway | Routes public subnet traffic to internet |
| NAT Gateway | Allows private subnet outbound internet (for updates) |
| Route Tables | Public → IGW, Private → NAT GW |

### 3.2 EC2 Instances
| Instance | Subnet | Purpose | Access |
|----------|--------|---------|--------|
| Web Server | Public | Hosts Node.js backend + React frontend | SSH (restricted to admin IP), HTTP/HTTPS (public) |
| DB Server | Private | Hosts MongoDB database | SSH (only via web server jump), MongoDB (only from web server) |

### 3.3 Security Groups
**Web Server SG:**
- Inbound: SSH (port 22, admin IP only), HTTP (80), HTTPS (443), Node.js (3001), React (3000)
- Outbound: All traffic allowed

**Database Server SG:**
- Inbound: SSH (port 22, from web server SG only), MongoDB (27017, from web server SG only)
- Outbound: All traffic (for package updates via NAT)

### 3.4 IAM Roles
- EC2 Role with SSM Managed Instance Core policy (for AWS Systems Manager)
- CloudWatch Agent policy (for monitoring)

---

## 4. Configuration & Deployment (Ansible)

### 4.1 Database Server Configuration
1. **MongoDB 7.0 Installation** — Added official MongoDB repository and installed
2. **Network Binding** — Configured to listen on all interfaces (0.0.0.0) for internal VPC access
3. **User Creation** — Created admin user and application-specific user with readWrite permissions
4. **Firewall (UFW)** — Only allows SSH (22) and MongoDB (27017) from VPC CIDR

### 4.2 Web Server Configuration
1. **Node.js 18 LTS** — Installed via NodeSource repository
2. **Application Cloning** — Git clone of TravelMemory repo
3. **Dependencies** — `npm install` for both backend and frontend
4. **Environment Variables** — `.env` files configured with MongoDB URI and backend URL
5. **Frontend Build** — React app built for production (`npm run build`)
6. **PM2 Process Manager** — Backend runs as a managed daemon with auto-restart
7. **Nginx Reverse Proxy** — Serves React static build and proxies API requests to Express backend
8. **Firewall (UFW)** — Allows SSH, HTTP, HTTPS, and application ports

### 4.3 Security Hardening
- SSH root login disabled
- Password authentication disabled (key-based only)
- UFW firewall with default-deny policy
- Security groups restrict access at AWS network level
- Private key file permissions set to 0400
- MongoDB accessible only within VPC
- Backend .env file permissions restricted (0600)

---

## 5. Application Component Interaction

```
User Browser
     │
     ▼
┌─────────────┐
│   Nginx     │ (Port 80)
│  (Web Srv)  │
└─────┬───────┘
      │
      ├── Static requests (/, /about, etc.)
      │         │
      │         ▼
      │   React Build Files (/home/ubuntu/TravelMemory/frontend/build)
      │
      └── API requests (/tripdetails, /api/*)
                │
                ▼
        ┌───────────────┐
        │  Express.js   │ (Port 3001)
        │   Backend     │
        └───────┬───────┘
                │
                ▼ (MongoDB connection via private IP)
        ┌───────────────┐
        │   MongoDB     │ (Port 27017, Private Subnet)
        │  (DB Server)  │
        └───────────────┘
```

1. **User** accesses the application via the web server's public IP on port 80
2. **Nginx** serves the React production build for frontend routes
3. **Nginx** proxies API requests to the Express.js backend (localhost:3001)
4. **Express.js** connects to MongoDB on the private subnet using the DB server's private IP
5. **MongoDB** stores travel memory entries and serves queries

---

## 6. Deployment Steps Summary

1. Terraform provisions VPC, subnets, gateways, security groups, IAM roles, and EC2 instances
2. Ansible configures the database server (MongoDB) first
3. Ansible then configures the web server (Node.js, app deployment, Nginx)
4. Application is accessible via `http://<web_server_public_ip>`

---

## 7. Testing & Verification

- **Backend API:** `curl http://<web_server_ip>:3001/tripdetails` returns JSON
- **Frontend:** Browser navigates to `http://<web_server_ip>` shows TravelMemory UI
- **Database:** MongoDB stores entries created via the frontend
- **SSH Security:** Only key-based auth works; root login denied
- **Network Isolation:** DB server not accessible from internet

---

## 8. Screenshots

> Place screenshots in the `/screenshots` directory showing:
> 1. Terraform apply output with resource creation
> 2. Ansible playbook execution output
> 3. Application running in browser
> 4. API response from backend
> 5. AWS Console showing EC2 instances, VPC, and Security Groups

---

## 9. Conclusion

The TravelMemory MERN application has been successfully deployed on AWS using Infrastructure as Code (Terraform) and Configuration Management (Ansible). The architecture follows security best practices with:
- Network isolation (public/private subnets)
- Principle of least privilege (security groups, IAM roles)
- Defense in depth (firewall + security groups + SSH hardening)
- Process management (PM2 for application reliability)
