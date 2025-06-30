# 🚀 Minecraft Server on Google Cloud with Terraform

This project provisions a [Forge-based Minecraft server](https://hub.docker.com/r/itzg/minecraft-server) on a Google Cloud Compute Engine (GCE) instance using Terraform. It sets up:

* A static external IP
* A firewall rule to allow traffic on port `25565`
* A VM instance running Docker and Docker Compose
* A Minecraft server container with mod support

---

## Prerequisites

1. **Install Terraform**
   [Terraform Download](https://developer.hashicorp.com/terraform/downloads)

   ```bash
   brew tap hashicorp/tap
   brew install hashicorp/tap/terraform
   ```

2. **Install Google Cloud CLI**
   [Google Cloud SDK Install Guide](https://cloud.google.com/sdk/docs/install)

3. **Authenticate with GCP**

   ```bash
   gcloud auth application-default login
   gcloud auth login
   ```

4. **Enable required APIs**

   ```bash
   gcloud services enable compute.googleapis.com
   ```

---

## Setup

1. Configure variables in `variables.tf`:

   ```hcl
   project_id = "your-gcp-project-id"
   region     = "us-central1"
   zone       = "us-central1-a"
   ```

2. **Initialize Terraform**

   ```bash
   terraform init
   ```

3. **Preview the plan**

   ```bash
   terraform plan
   ```

4. **Apply the configuration**

   ```bash
   terraform apply
   ```

   Confirm with `yes` when prompted.

---

## Validate Deployment

1. After `terraform apply`, note the static external IP.

2. Launch Minecraft and connect to:

   ```text
   <STATIC_EXTERNAL_IP>:25565
   ```

   > Note: It takes roughly 5 minutes for the server to start and generate the world.

3. To manage the server:

   ```bash
   gcloud compute ssh minecraft-server-instance --zone=<your-zone>
   docker logs -t minecraft-server-instance
   ```

## Cleanup

Destroy all resources created by Terraform:

```bash
terraform destroy
```
