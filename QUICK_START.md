# Terraform & Ansible - Complete Workflow Explained

## Table of Contents
1. [Understanding the Big Picture](#understanding-the-big-picture)
2. [Terraform Deep Dive](#terraform-deep-dive)
3. [Ansible Deep Dive](#ansible-deep-dive)
4. [Complete Workflow](#complete-workflow)
5. [Real-World Example](#real-world-example)

---

## Understanding the Big Picture

### The Problem We're Solving

**Without Infrastructure as Code (IaC):**
```
Manual Process:
1. Login to AWS Console
2. Click "Launch Instance"
3. Choose AMI, instance type, network, etc.
4. SSH to server
5. Manually install Docker: apt install docker.io
6. Copy application files
7. Start application
8. Repeat for each server...

Problems:
- Time consuming (30+ minutes per server)
- Error prone (forget a step, typo in command)
- Not reproducible (hard to do exactly the same twice)
- Not documented (what did you do 6 months ago?)
- Not scalable (100 servers = 100 manual setups)
```

**With Terraform + Ansible:**
```
Automated Process:
1. Write code once (Terraform + Ansible)
2. Run: terraform apply
3. Run: ansible-playbook deploy.yml
4. Done! All servers configured identically

Benefits:
- Fast (3-5 minutes total)
- Consistent (same every time)
- Reproducible (run again = same result)
- Documented (code IS documentation)
- Scalable (2 servers or 200 = same effort)
```

---

## Terraform Deep Dive

### What is Terraform?

**Simple Definition:** Terraform creates infrastructure (servers, networks, databases) by writing code instead of clicking in a web interface.

**Analogy:** Think of Terraform like a construction blueprint. The blueprint describes what to build, and Terraform is the construction company that builds it.

### Core Concepts

#### 1. Infrastructure as Code (IaC)

Instead of this (manual):
```
1. Go to AWS Console
2. Click EC2
3. Click "Launch Instance"
4. Select Ubuntu
5. Select t2.micro
6. Click through 7 pages
7. Click "Launch"
```

You write this (code):
```hcl
resource "aws_instance" "web" {
  ami           = "ami-0c7217cdde317cfec"
  instance_type = "t2.micro"
}
```

Then run: `terraform apply`

#### 2. Declarative vs Imperative

**Imperative (traditional scripting):**
```bash
# You tell HOW to do it (step by step)
create_server("web1")
if server_exists("web1"):
    update_server("web1")
else:
    create_server("web1")
```

**Declarative (Terraform):**
```hcl
# You tell WHAT you want (desired state)
resource "aws_instance" "web" {
  count = 2
  ami   = "ami-123"
}

# Terraform figures out HOW to get there
```

**What Terraform does:**
1. Reads your code (what you want)
2. Checks current state (what exists now)
3. Calculates difference (what needs to change)
4. Makes changes (creates, updates, or deletes)

#### 3. Terraform Workflow

```
┌─────────────────────────────────────────────────────────────┐
│                    TERRAFORM WORKFLOW                        │
└─────────────────────────────────────────────────────────────┘

Step 1: WRITE
├─ You write .tf files describing infrastructure
├─ Example: "I want 2 EC2 instances"
└─ Files: main.tf, variables.tf, outputs.tf

Step 2: INIT
├─ Command: terraform init
├─ Downloads required providers (AWS, Azure, etc.)
├─ Creates .terraform/ folder
└─ Initializes backend (where to store state)

Step 3: PLAN
├─ Command: terraform plan
├─ Reads your .tf files
├─ Compares with current infrastructure
├─ Shows what will change
├─ Output: "Will create 2 instances, 1 security group"
└─ NO CHANGES MADE (safe, read-only)

Step 4: APPLY
├─ Command: terraform apply
├─ Asks for confirmation (type "yes")
├─ Makes API calls to AWS
├─ Creates/updates/deletes resources
├─ Saves state to terraform.tfstate
└─ Shows outputs (IP addresses, etc.)

Step 5: MANAGE
├─ Infrastructure now exists
├─ State file tracks everything
├─ Can update: modify .tf files, run apply again
└─ Can destroy: terraform destroy
```

#### 4. Terraform State

**What is State?**
State is a JSON file (`terraform.tfstate`) that tracks what Terraform created.

**Why is State Important?**
```
Without State:
- Terraform doesn't know what it created before
- Can't update existing resources
- Would try to create duplicates
- Would lose track of infrastructure

With State:
- Terraform remembers everything it created
- Can update resources (not recreate)
- Can show current infrastructure
- Can calculate minimal changes needed
```

**Example State File:**
```json
{
  "version": 4,
  "resources": [
    {
      "type": "aws_instance",
      "name": "web",
      "instances": [
        {
          "attributes": {
            "id": "i-1234567890abcdef0",
            "public_ip": "54.123.45.67",
            "instance_type": "t2.micro"
          }
        }
      ]
    }
  ]
}
```

#### 5. Terraform Resources vs Data Sources

**Resource** - Something Terraform CREATES
```hcl
# Terraform will CREATE this
resource "aws_instance" "web" {
  ami           = "ami-123"
  instance_type = "t2.micro"
}
```

**Data Source** - Something that ALREADY EXISTS
```hcl
# Terraform will READ this (not create)
data "aws_vpc" "default" {
  default = true
}

# Use the existing VPC ID
resource "aws_instance" "web" {
  vpc_id = data.aws_vpc.default.id
}
```

#### 6. Terraform Variables

**Why Variables?**
- Reuse values
- Change behavior without editing code
- Environment-specific values (dev, staging, prod)

**Three Ways to Define Variables:**

**A) Variable Definition (variables.tf)**
```hcl
variable "instance_count" {
  description = "Number of instances to create"
  type        = number
  default     = 2
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}
```

**B) Variable Values (terraform.tfvars)**
```hcl
instance_count = 5
aws_region     = "eu-west-1"
```

**C) Using Variables (main.tf)**
```hcl
resource "aws_instance" "web" {
  count         = var.instance_count
  ami           = "ami-123"
  instance_type = "t2.micro"
}
```

#### 7. Terraform Outputs

**Purpose:** Display information after infrastructure is created

```hcl
output "server_ips" {
  description = "Public IP addresses of servers"
  value       = aws_instance.web[*].public_ip
}

output "server_ids" {
  description = "Instance IDs"
  value       = aws_instance.web[*].id
}
```

**Usage:**
```bash
# After terraform apply
terraform output

# Output:
# server_ips = [
#   "54.123.45.67",
#   "3.234.56.78"
# ]

# Use in scripts
IP=$(terraform output -raw server_ips[0])
ssh ubuntu@$IP
```

---

## Ansible Deep Dive

### What is Ansible?

**Simple Definition:** Ansible configures servers (installs software, copies files, starts services) using playbooks written in YAML.

**Analogy:** If Terraform builds the house, Ansible furnishes and decorates it.

### Core Concepts

#### 1. Configuration Management

**What is Configuration Management?**
Making sure all servers are configured the same way.

**Example:**
```
Without Ansible:
- Server 1: Docker 20.10.5, Nginx 1.18, App v1.0
- Server 2: Docker 19.03.1, Nginx 1.14, App v0.9
- Server 3: No Docker, No Nginx, No App
Problem: Inconsistent, hard to maintain

With Ansible:
- All servers: Docker 20.10.5, Nginx 1.18, App v1.0
- Consistent, predictable, maintainable
```

#### 2. Agentless Architecture

**How Ansible Works:**
```
Traditional Tools (Chef, Puppet):
┌──────────┐         ┌──────────┐
│ Control  │────────▶│ Server 1 │
│ Server   │         │ (Agent)  │
└──────────┘         └──────────┘
                     ┌──────────┐
                     │ Server 2 │
                     │ (Agent)  │
                     └──────────┘

- Need to install agent on every server
- Agents constantly checking for updates
- More complex

Ansible:
┌──────────┐    SSH  ┌──────────┐
│ Control  │────────▶│ Server 1 │
│ Machine  │         │ (No Agent)│
└──────────┘         └──────────┘
                 SSH ┌──────────┐
                     │ Server 2 │
                     │ (No Agent)│
                     └──────────┘

- Uses SSH (already exists)
- No agent needed
- Simpler, lighter
```

#### 3. Ansible Inventory

**What is Inventory?**
A list of servers that Ansible will manage.

**Simple Inventory (INI format):**
```ini
[webservers]
web1 ansible_host=54.123.45.67
web2 ansible_host=3.234.56.78

[databases]
db1 ansible_host=52.123.45.67

[all:vars]
ansible_user=ubuntu
ansible_ssh_private_key_file=~/.ssh/key.pem
```

**Groups:**
- `[webservers]` - Group name
- `web1` - Host alias (friendly name)
- `ansible_host` - Actual IP address

**Dynamic Inventory:**
Instead of hardcoding IPs, query AWS to get current servers:
```yaml
plugin: aws_ec2
regions:
  - us-east-1
filters:
  tag:Environment: production
```

#### 4. Ansible Playbooks

**What is a Playbook?**
A YAML file that describes tasks to perform on servers.

**Structure:**
```yaml
---
- name: Install Docker              # Play name (what you're doing)
  hosts: webservers                 # Which servers
  become: yes                       # Use sudo
  tasks:                            # List of tasks
    - name: Update apt cache        # Task 1
      apt:
        update_cache: yes
    
    - name: Install Docker          # Task 2
      apt:
        name: docker.io
        state: present
```

**Anatomy of a Task:**
```yaml
- name: Install Docker              # Human-readable description
  apt:                              # Module name (what action)
    name: docker.io                 # Module parameters
    state: present
  become: yes                       # Privilege escalation
  when: ansible_os_family == "Debian"  # Condition (optional)
```

#### 5. Ansible Modules

**What are Modules?**
Pre-built functions that perform actions (install package, copy file, start service).

**Common Modules:**

| Module | Purpose | Example |
|--------|---------|---------|
| `apt` | Manage packages (Debian/Ubuntu) | Install Docker |
| `yum` | Manage packages (RedHat/CentOS) | Install Nginx |
| `copy` | Copy files to servers | Copy config file |
| `template` | Copy files with variables | Copy config with server IP |
| `service` | Manage services | Start/stop/restart |
| `docker_container` | Manage Docker containers | Run container |
| `command` | Run shell commands | Run script |
| `shell` | Run shell commands with pipes | `ps aux | grep nginx` |

**Example Using Different Modules:**
```yaml
- name: Setup web server
  hosts: webservers
  tasks:
    - name: Install Nginx
      apt:
        name: nginx
        state: present
    
    - name: Copy config file
      copy:
        src: /local/nginx.conf
        dest: /etc/nginx/nginx.conf
    
    - name: Start Nginx
      service:
        name: nginx
        state: started
        enabled: yes
    
    - name: Check if running
      command: systemctl status nginx
      register: nginx_status
    
    - name: Show status
      debug:
        var: nginx_status.stdout
```

#### 6. Ansible Idempotency

**What is Idempotency?**
Running the same playbook multiple times produces the same result (no unnecessary changes).

**Example:**
```yaml
- name: Install Docker
  apt:
    name: docker.io
    state: present

# First run: Installs Docker (changed)
# Second run: Docker already installed (ok, no change)
# Third run: Docker already installed (ok, no change)
```

**Benefits:**
- Safe to run playbooks repeatedly
- Only makes necessary changes
- Fast (skips what's already correct)

#### 7. Ansible Variables

**Where Variables Come From:**
```yaml
# 1. Playbook variables
- name: Example
  hosts: all
  vars:
    app_port: 8080
    app_name: myapp
  tasks:
    - debug:
        msg: "{{ app_name }} runs on port {{ app_port }}"

# 2. Inventory variables
[webservers]
web1 ansible_host=1.2.3.4 app_version=1.0

# 3. Facts (automatically gathered)
- debug:
    msg: "OS is {{ ansible_distribution }}"
    # Output: OS is Ubuntu

# 4. Registered variables (from task output)
- name: Get disk usage
  command: df -h
  register: disk_usage

- debug:
    var: disk_usage.stdout
```

#### 8. Ansible Handlers

**What are Handlers?**
Tasks that run only if something changed (typically to restart services).

**Example:**
```yaml
- name: Update Nginx config
  hosts: webservers
  tasks:
    - name: Copy new config
      copy:
        src: nginx.conf
        dest: /etc/nginx/nginx.conf
      notify: Restart Nginx          # Trigger handler
    
    - name: Copy SSL cert
      copy:
        src: cert.pem
        dest: /etc/nginx/cert.pem
      notify: Restart Nginx          # Trigger handler

  handlers:
    - name: Restart Nginx            # Handler definition
      service:
        name: nginx
        state: restarted

# Restart happens ONCE at the end, even if multiple tasks notify
```

---

## Complete Workflow

### The Full Process: Terraform + Ansible

```
PHASE 1: INFRASTRUCTURE (Terraform)
┌─────────────────────────────────────────────────────────────┐
│ 1. Write Terraform Code                                      │
│    ├─ Define infrastructure (servers, networks, etc.)        │
│    └─ Save in .tf files                                      │
│                                                              │
│ 2. terraform init                                            │
│    ├─ Downloads AWS provider                                 │
│    └─ Initializes backend                                    │
│                                                              │
│ 3. terraform plan                                            │
│    ├─ Shows what will be created                             │
│    └─ Safe, no changes made                                  │
│                                                              │
│ 4. terraform apply                                           │
│    ├─ Creates servers in AWS                                 │
│    ├─ Saves state (what was created)                         │
│    └─ Outputs: server IPs                                    │
└─────────────────────────────────────────────────────────────┘
                            ↓
                    Servers exist but empty
                    (just OS, no software)
                            ↓
PHASE 2: CONFIGURATION (Ansible)
┌─────────────────────────────────────────────────────────────┐
│ 5. Create Ansible Inventory                                 │
│    ├─ List server IPs from Terraform output                 │
│    └─ Group servers (webservers, databases, etc.)           │
│                                                              │
│ 6. Write Ansible Playbook                                   │
│    ├─ Define what to install                                │
│    └─ Define how to configure                               │
│                                                              │
│ 7. ansible-playbook setup.yml                               │
│    ├─ Connects to servers via SSH                           │
│    ├─ Installs software (Docker, Nginx, etc.)               │
│    ├─ Copies configuration files                            │
│    └─ Starts services                                       │
│                                                              │
│ 8. ansible-playbook deploy.yml                              │
│    ├─ Deploys application                                   │
│    ├─ Starts containers                                     │
│    └─ Verifies everything works                             │
└─────────────────────────────────────────────────────────────┘
                            ↓
                Application running on all servers
```

### Data Flow

```
1. You → Terraform Code → AWS API → Infrastructure Created
                                        ↓
2. Terraform → terraform.tfstate ← Records what was created
                                        ↓
3. terraform output → Server IPs
                                        ↓
4. Server IPs → Ansible Inventory
                                        ↓
5. You → Ansible Playbook → SSH → Servers → Software Installed
                                        ↓
6. Configured servers running your application
```

### Communication Flow

```
┌──────────────┐  Terraform    ┌──────────────┐
│ Your Machine │──────────────▶│  AWS API     │
│              │               │              │
│  terraform   │               │ Creates:     │
│  ansible     │               │ - EC2        │
│              │               │ - Security   │
└──────────────┘               │ - Network    │
       │                       └──────────────┘
       │                              │
       │                              ↓
       │                       ┌──────────────┐
       │                       │ Server 1     │
       │          SSH          │ 54.1.2.3     │
       └──────────────────────▶│              │
                               └──────────────┘
       │          SSH          ┌──────────────┐
       └──────────────────────▶│ Server 2     │
                               │ 3.4.5.6      │
                               └──────────────┘
```

---

## Real-World Example

### Scenario: Deploy Web Application

**Goal:** Create 3 web servers with Docker and deploy a Node.js app

### Step 1: Terraform Code

**terraform/main.tf:**
```hcl
# Create 3 servers
resource "aws_instance" "web" {
  count         = 3
  ami           = "ami-0c7217cdde317cfec"
  instance_type = "t2.micro"
  key_name      = "mykey"
  
  tags = {
    Name = "web-${count.index + 1}"
    Role = "webserver"
  }
}

# Output IPs for Ansible
output "server_ips" {
  value = aws_instance.web[*].public_ip
}
```

### Step 2: Run Terraform

```bash
$ terraform apply

# Output:
# server_ips = [
#   "54.123.45.1",
#   "54.123.45.2",
#   "54.123.45.3"
# ]
```

### Step 3: Ansible Inventory

**ansible/inventory/hosts:**
```ini
[webservers]
web1 ansible_host=54.123.45.1
web2 ansible_host=54.123.45.2
web3 ansible_host=54.123.45.3

[webservers:vars]
ansible_user=ubuntu
ansible_ssh_private_key_file=~/.ssh/mykey.pem
```

### Step 4: Ansible Playbook

**ansible/playbooks/deploy.yml:**
```yaml
---
- name: Setup and deploy web application
  hosts: webservers
  become: yes
  
  vars:
    app_port: 3000
    app_version: "1.0.0"
  
  tasks:
    # Step 1: Install Docker
    - name: Install Docker
      apt:
        name: docker.io
        state: present
        update_cache: yes
    
    # Step 2: Start Docker service
    - name: Start Docker
      service:
        name: docker
        state: started
        enabled: yes
    
    # Step 3: Pull application image
    - name: Pull Node.js application
      docker_image:
        name: "myapp:{{ app_version }}"
        source: pull
    
    # Step 4: Run container
    - name: Run application container
      docker_container:
        name: myapp
        image: "myapp:{{ app_version }}"
        state: started
        restart_policy: always
        ports:
          - "{{ app_port }}:3000"
    
    # Step 5: Verify it's running
    - name: Wait for application
      wait_for:
        port: "{{ app_port }}"
        delay: 5
        timeout: 30
    
    # Step 6: Test application
    - name: Test application response
      uri:
        url: "http://localhost:{{ app_port }}/health"
        return_content: yes
      register: health_check
    
    - name: Show health check result
      debug:
        msg: "Application is {{ health_check.json.status }}"
```

### Step 5: Run Ansible

```bash
$ ansible-playbook playbooks/deploy.yml

# Output shows progress:
PLAY [Setup and deploy web application]
TASK [Install Docker]                    *** changed: [web1]
TASK [Install Docker]                    *** changed: [web2]
TASK [Install Docker]                    *** changed: [web3]
TASK [Start Docker]                      *** ok: [web1]
TASK [Pull Node.js application]          *** changed: [web1]
...
PLAY RECAP
web1: ok=7  changed=4  unreachable=0  failed=0
web2: ok=7  changed=4  unreachable=0  failed=0
web3: ok=7  changed=4  unreachable=0  failed=0
```

### Result

```
All 3 servers now have:
- Docker installed
- Application container running
- Accessible on port 3000
- Automatically restart on failure
- Identical configuration
```

---

## Key Differences: Terraform vs Ansible

| Aspect | Terraform | Ansible |
|--------|-----------|---------|
| **Purpose** | Create infrastructure | Configure infrastructure |
| **What it does** | Servers, networks, databases | Install software, deploy apps |
| **When to use** | Beginning (create resources) | After (configure resources) |
| **Language** | HCL (HashiCorp Language) | YAML |
| **State** | Keeps state file | No state (idempotent) |
| **Execution** | Declarative (what you want) | Procedural (steps to follow) |
| **Target** | Cloud providers (AWS, Azure) | Any server with SSH |
| **Change tracking** | terraform.tfstate | No built-in tracking |

---

## Best Practices

### Terraform Best Practices

1. **Always use version control (Git)**
```bash
git init
git add *.tf
git commit -m "Initial infrastructure"
```

2. **Use remote state for teams**
```hcl
terraform {
  backend "s3" {
    bucket = "my-terraform-state"
    key    = "prod/terraform.tfstate"
    region = "us-east-1"
  }
}
```

3. **Use modules for reusability**
```hcl
module "web_servers" {
  source = "./modules/ec2"
  count  = 3
}
```

4. **Tag everything**
```hcl
tags = {
  Environment = "production"
  Project     = "web-app"
  ManagedBy   = "terraform"
}
```

### Ansible Best Practices

1. **Use roles for organization**
```
roles/
├── docker/
│   └── tasks/
│       └── main.yml
├── nginx/
│   └── tasks/
│       └── main.yml
└── app/
    └── tasks/
        └── main.yml
```

2. **Use variables for flexibility**
```yaml
vars:
  app_port: 8080
  app_name: "myapp"
  app_version: "{{ lookup('env', 'APP_VERSION') | default('latest') }}"
```

3. **Use handlers for service restarts**
```yaml
tasks:
  - name: Update config
    copy:
      src: app.conf
      dest: /etc/app/app.conf
    notify: Restart app

handlers:
  - name: Restart app
    service:
      name: app
      state: restarted
```

4. **Test with check mode**
```bash
ansible-playbook playbook.yml --check  # Dry run
```

---

## Summary

**Terraform:**
- Creates infrastructure (the servers)
- Manages cloud resources
- Keeps track of state
- Run once to create, modify to update

**Ansible:**
- Configures infrastructure (what's on the servers)
- Installs and manages software
- Deploys applications
- Run repeatedly (idempotent)

**Together:**
```
Terraform → Creates empty servers
     ↓
Ansible → Installs software and deploys apps
     ↓
Working application on cloud infrastructure
```

**When to use what:**
- **Terraform:** "I need 5 servers with these specifications"
- **Ansible:** "Install Docker, Nginx, and my app on those servers"