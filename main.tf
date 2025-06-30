terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.10"
    }
  }
}

provider "google" {
  project = var.gcp_project
  region  = var.gcp_region
  zone    = var.gcp_zone
}

// Configure static ip for vm
resource "google_compute_address" "minecraft_server_ip" {
  name   = "my-static-ip"
  region = var.gcp_region
}

// Configure ingress minecraft traffic on port 25565
resource "google_compute_firewall" "minecraft_firewall" {
  name    = "minecraft-firewall"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["25565"]
  }

  target_tags = ["minecraft-server"]

  source_ranges = ["0.0.0.0/0"]
}


// Provision gce instance with a static ip to host the minecraft server
resource "google_compute_instance" "minecraft_server_instance" {
  name         = "minecraft-server-instance"
  machine_type = "e2-medium" // f1-micro for terraform testing
  zone         = var.gcp_zone

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-12"
    }
  }

  network_interface {
    network = "default" // Use default gcp network
    access_config {
      nat_ip = google_compute_address.minecraft_server_ip.address
    }
  }

  // Tag the vm to allow minecraft traffic
  tags = ["minecraft-server"]

  // Install docker, setup docker compose and run the minecraft server container
  // See https://hub.docker.com/r/itzg/minecraft-server
  metadata_startup_script = <<-EOS
    #! /bin/bash

    # Add Docker's official GPG key:
    sudo apt-get update
    sudo apt-get install ca-certificates curl gnupg
    sudo install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    sudo chmod a+r /etc/apt/keyrings/docker.gpg

    # Add the repository to Apt sources:
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian \
      $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
      sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt-get update

    # Install Docker
    yes Y | apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

    # Install Docker Compose
    apt-get install -y docker-compose

    # Start Docker daemon
    systemctl start docker

    # Pull the Minecraft server Docker image
    docker pull itzg/minecraft-server

    # Create the minecraft directory
    mkdir -p /minecraft

    # Create the Docker Compose file
    cat <<EOF > /minecraft/docker-compose.yml
    version: "3.8"

    services:
      mc:
        image: itzg/minecraft-server
        ports:
        - "25565:25565"
        environment:
          SERVER_NAME: "Rooterbuster's Minecraft Server"
          EULA: "TRUE"
          ONLINE_MODE: "FALSE"
          EXEC_DIRECTLY: "true"
          RCON_PASSWORD: "root1999"
          TYPE: "FORGE"
          DEBUG: "true"
          OVERRIDE_SERVER_PROPERTIES: "true"
          DIFFICULTY: "easy"
          MAX_TICK_TIME: "-1"
          ALLOW_FLIGHT: "true"
          ENABLE_COMMAND_BLOCK: "true"
          SNOOPER_ENABLED: "false"
          MAX_MEMORY: "3G"
        volumes:
        - mc_forge:/data
        - ./mods:/mods:ro

    volumes:
      mc_forge: {}
    EOF

    # Create a directory for mods (if you have any mods to include)
    mkdir -p /minecraft/mods

    # Navigate to the directory and start the Minecraft server
    cd /minecraft
    docker-compose up -d
  EOS
}
