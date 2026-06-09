# DRAPE — Wholesale Clothing Shop
### BTEC Unit 6: Networking in the Cloud — Architecture & Deployment Guide

---

## Project Structure

```
wholesale-shop/
│
├── backend/                   # Node.js / Express API
│   ├── server.js              # Main application entry point
│   ├── db.js                  # PostgreSQL connection pool
│   ├── package.json
│   ├── .env.example           # Environment variable template
│   └── routes/
│       ├── products.js        # GET/POST/PUT/DELETE /api/products
│       └── orders.js          # GET/POST /api/orders
│
├── frontend/
│   ├── public/                # Customer-facing shop
│   │   ├── index.html
│   │   ├── style.css
│   │   └── app.js
│   └── admin/                 # Admin panel / CRM
│       ├── index.html
│       ├── admin.css
│       └── admin.js
│
├── database/
│   └── schema.sql             # PostgreSQL schema + seed data
│
├── nginx/
│   └── nginx.conf             # Reverse proxy config (mimics ALB)
│
├── Dockerfile                 # Multi-stage build for backend
├── docker-compose.yml         # Full local stack
└── README.md
```

---

## Quick Start (Local)

```bash
# 1. Clone / download the project
cd wholesale-shop

# 2. Copy environment file
cp backend/.env.example backend/.env

# 3. Build and start all services
docker compose up --build

# 4. Open in browser
#    Shop:  http://localhost
#    Admin: http://localhost/admin
#    API:   http://localhost/api/products
```

---

## API Reference

| Method | Endpoint               | Description              |
|--------|------------------------|--------------------------|
| GET    | /api/products          | List all products        |
| GET    | /api/products?category=X | Filter by category     |
| GET    | /api/products/:id      | Get single product       |
| POST   | /api/products          | Create product           |
| PUT    | /api/products/:id      | Update product           |
| DELETE | /api/products/:id      | Delete product           |
| GET    | /api/orders            | List all orders          |
| POST   | /api/orders            | Place new order          |
| GET    | /health                | Health check             |

---

## AWS Cloud Architecture (BTEC Report Section)

### Overview

This section explains how to deploy this application to AWS in a way that
is secure, scalable, and highly available — directly addressing the
Unit 6 networking requirements.

---

### 1. VPC (Virtual Private Cloud)

A **VPC** is a logically isolated section of the AWS cloud. Think of it as
your own private data centre inside AWS, where you control all networking.

**Our VPC design:**
```
VPC: 10.0.0.0/16  (65,536 IP addresses)
```

The `/16` CIDR block gives us room to create many subnets.

---

### 2. Subnets — Public vs Private

We split the VPC into two types of subnet across **two Availability Zones**
(AZs) for fault tolerance. Using two AZs means the system survives if one
AWS data centre goes offline.

```
┌─────────────────────────────── VPC: 10.0.0.0/16 ────────────────────────────────┐
│                                                                                  │
│  ┌── Availability Zone A ──────────┐  ┌── Availability Zone B ──────────┐       │
│  │                                 │  │                                 │       │
│  │  PUBLIC SUBNET  10.0.1.0/24     │  │  PUBLIC SUBNET  10.0.2.0/24     │       │
│  │  ┌─────────────────────────┐    │  │  ┌─────────────────────────┐    │       │
│  │  │  Application Load       │    │  │  │  Application Load       │    │       │
│  │  │  Balancer (ALB node)    │    │  │  │  Balancer (ALB node)    │    │       │
│  │  │  NAT Gateway            │    │  │  │  NAT Gateway            │    │       │
│  │  └─────────────────────────┘    │  │  └─────────────────────────┘    │       │
│  │                                 │  │                                 │       │
│  │  PRIVATE SUBNET 10.0.3.0/24     │  │  PRIVATE SUBNET 10.0.4.0/24     │       │
│  │  ┌─────────────────────────┐    │  │  ┌─────────────────────────┐    │       │
│  │  │  EC2 / ECS App Instance │    │  │  │  EC2 / ECS App Instance │    │       │
│  │  │  (Node.js server)       │    │  │  │  (Node.js server)       │    │       │
│  │  └─────────────────────────┘    │  │  └─────────────────────────┘    │       │
│  │                                 │  │                                 │       │
│  │  DB SUBNET      10.0.5.0/24     │  │  DB SUBNET      10.0.6.0/24     │       │
│  │  ┌─────────────────────────┐    │  │  ┌─────────────────────────┐    │       │
│  │  │  RDS PostgreSQL         │    │  │  │  RDS PostgreSQL          │    │       │
│  │  │  (Primary)              │    │  │  │  (Standby/Replica)       │    │       │
│  │  └─────────────────────────┘    │  │  └─────────────────────────┘    │       │
│  └─────────────────────────────────┘  └─────────────────────────────────┘       │
└──────────────────────────────────────────────────────────────────────────────────┘
```

**Why this matters:**
- **Public subnets** have a route to the **Internet Gateway** — resources here
  can receive traffic from the internet (ALB).
- **Private subnets** have NO direct internet route — EC2 app instances are
  unreachable from the internet. Outbound traffic (e.g. npm installs) goes via
  the **NAT Gateway** in the public subnet.
- **DB subnets** are the most isolated — RDS has no internet route at all.

---

### 3. Internet Gateway & NAT Gateway

| Component        | Role                                                          |
|-----------------|---------------------------------------------------------------|
| Internet Gateway | Attached to VPC. Allows PUBLIC subnets ↔ Internet            |
| NAT Gateway      | In public subnet. Allows private instances to reach internet (one-way) |

Traffic flow for a customer request:
```
Internet → Internet Gateway → ALB (public subnet)
         → App Instance (private subnet)
         → RDS PostgreSQL (DB subnet)
```

The database **never** receives traffic directly from the internet.

---

### 4. Security Groups (Firewall Rules)

Security Groups act as virtual firewalls for each AWS resource. They are
**stateful** — if you allow inbound traffic, the response is automatically
allowed outbound.

**Security Group: alb-sg (Load Balancer)**
```
Inbound:
  HTTP  port 80   from 0.0.0.0/0   (anyone on internet)
  HTTPS port 443  from 0.0.0.0/0   (anyone on internet)
Outbound:
  All traffic → app-sg (only to app instances)
```

**Security Group: app-sg (EC2 / ECS App Instances)**
```
Inbound:
  TCP port 3000   from alb-sg ONLY  ← cannot be reached directly from internet
Outbound:
  TCP port 5432   → db-sg           (PostgreSQL)
  HTTPS port 443  → 0.0.0.0/0       (to pull packages, call external APIs)
```

**Security Group: db-sg (RDS PostgreSQL)**
```
Inbound:
  TCP port 5432   from app-sg ONLY  ← the database is completely hidden
Outbound:
  None required
```

This **layered security** means that even if a hacker found the RDS
endpoint, they could not connect because the security group rejects all
traffic that doesn't come from app-sg.

---

### 5. Application Load Balancer (ALB)

The ALB distributes incoming HTTP requests across multiple EC2/ECS
instances running the Node.js app.

**Key ALB concepts:**

- **Listener**: Listens on port 80 (HTTP) and/or 443 (HTTPS).
- **Target Group**: The set of EC2/ECS instances to route to.
- **Health Checks**: ALB calls `GET /health` every 30 seconds.
  If an instance returns a non-200 response, ALB stops sending it traffic
  and AWS can automatically replace it.
- **Round Robin**: By default, requests are distributed evenly.

```
Request 1 → Instance A (10.0.3.10)
Request 2 → Instance B (10.0.4.10)
Request 3 → Instance A
...
```

This means if you have 3 app instances and one crashes, the other two
handle 100% of traffic with no downtime.

---

### 6. RDS PostgreSQL

Instead of running PostgreSQL in a Docker container (like locally), in AWS
we use **Amazon RDS** — a managed database service.

Benefits over self-managed:
- Automated backups and point-in-time recovery
- Automatic failover to standby replica in another AZ (Multi-AZ)
- Managed OS patching — no manual maintenance
- Easy vertical scaling (change instance type)

The only change needed in the app is the `DB_HOST` environment variable:
```
# Local (docker-compose)
DB_HOST=db

# AWS Production
DB_HOST=wholesale-db.xxxxxxxx.eu-west-1.rds.amazonaws.com
```

---

### 7. AWS Services Summary Table

| AWS Service            | Local Equivalent         | Purpose                              |
|------------------------|--------------------------|--------------------------------------|
| VPC                    | Docker network           | Isolated network boundary            |
| Internet Gateway       | Host machine port 80     | Entry point for internet traffic     |
| Public Subnet          | public_net Docker network| Houses ALB and NAT Gateway           |
| Private Subnet         | private_net Docker network| Houses app instances                |
| NAT Gateway            | Docker bridge network    | Outbound internet for private subnet |
| ALB (Load Balancer)    | nginx reverse proxy      | Distributes traffic, health checks   |
| EC2 / ECS              | Docker container (app)   | Runs Node.js application             |
| RDS PostgreSQL         | Docker container (db)    | Managed relational database          |
| Security Groups        | Docker network isolation | Firewall rules per resource          |

---

### 8. Scalability

To handle more traffic, AWS Auto Scaling can automatically add EC2
instances when CPU > 70% and remove them when traffic drops.

```
Low traffic:   1 instance   (cost efficient)
Normal:        2 instances  (default)
High traffic:  up to 6      (Auto Scaling adds more)
```

The ALB automatically detects new instances and starts routing to them.
The database connection pool in `db.js` handles multiple app instances
connecting simultaneously.

---

*BTEC Unit 6 — Networking in the Cloud | Wholesale Shop Project*
