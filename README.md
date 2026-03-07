## React AWS Infrastructure Deployment

<p> This project demonstrates how to deploy a React application on AWS EC2 using Infrastructure as Code and configuration automation. The infrastructure is provisioned with Terraform, while server configuration and application deployment are automated using Ansible.</p>

<p> The goal of this project is to create a secure, reproducible, and automated deployment pipeline for hosting a React single-page application.</p>

<hr/>

## Architecture Overview

The deployment consists of:

<strong> Terraform </strong>

* Provisions AWS infrastructure

* Creates EC2 instance

* Creates Security Group

* Generates SSH key

* Configures networking

<strong> Ansible</strong> 

* Hardens the server

* Installs and configures Apache

* Configures firewall (UFW)

* Configures Fail2Ban

* Deploys the React build

<strong> Apache</strong>

* Serves the React build

* Handles SPA routing

* Adds security headers

<hr/>

## Infrastructure Components

| Component | Purpose
| -------- | -------- 
| EC2 | Hosts the React application
| Security Group | Controls inbound traffic 
| SSH | Secure remote access   
| Apache | Web server for React build
| UFW | Host firewall  
|Fail2Ban | Protects against brute-force attacks 


## Deployment Workflow
1️⃣  <strong> Provision Infrastructure</strong>
```
terraform init
terraform plan
terraform apply
```

This creates:

* EC2 instance

* Security group

* SSH key pair

* Network configuration


2️⃣ <strong>  Configure Server</strong>

Run the Ansible playbook:
```
ansible-playbook -i inventory playbook.yml
```

The playbook will:

* Update the system

* Harden SSH

* Install Apache

* Configure firewall

* Install Fail2Ban

* Deploy the React application

<hr/>

## React SPA Configuration

Apache is configured to support React Router using rewrite rules.

Example .htaccess:
```
RewriteEngine On
RewriteBase /
RewriteRule ^index\.html$ - [L]

RewriteCond %{REQUEST_FILENAME} !-f
RewriteCond %{REQUEST_FILENAME} !-d

RewriteRule . /index.html [L]
```

This ensures all routes fallback to index.html, enabling client-side routing.

<hr />

Security Hardening

The server is hardened using several techniques:

 <strong> SSH Hardening</strong> 

Custom SSH port

Root login disabled

Password authentication disabled

Max authentication attempts limited

 <strong> Firewall</strong> 

UFW allows only:

* SSH

* HTTP

* HTTPS

 <strong> Fail2Ban </strong>

* Blocks repeated failed SSH attempts

* Monitors Apache logs for malicious requests

<hr/>

### Lessons Learned

During development several common pitfalls were encountered:

* Incorrect Security Group rules can lock you out of the server

* Apache directory options can break .htaccess rewrites

* Hardening SSH without verifying keys can break remote access

These lessons highlight the importance of incremental security changes and testing.

<hr/>

#### Future Improvements

Planned improvements include:

* Automating Apache VirtualHost configuration entirely in Ansible

* Adding domain name and HTTPS with Let's Encrypt

* Automating deployments through CI/CD

* Adding monitoring and logging

* Removing the need for manual SSH access

* Repository Structure