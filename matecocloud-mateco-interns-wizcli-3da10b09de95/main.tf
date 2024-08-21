variable "google_service_account_key" {
  type = string
}

terraform {
  backend "gcs"{
    bucket = "pe3bucket"
    prefix = "terraform/state"
  }
  required_providers {
    google = {
      source = "hashicorp/google"
      version = "4.51.0"
    }
  }
}

provider "google" {
  credentials = var.google_service_account_key
  project = "mateco-interns"
  region  = "europe-west1"
  zone    = "europe-west1-b"
}

#Router
resource "google_compute_router" "pe3router"{
    name    ="pe3router"
    region  ="europe-west1"
    network = google_compute_network.main.id
}

#Subnets (enkel private)
resource "google_compute_subnetwork" "private" {
    name                    ="private"
    ip_cidr_range           ="10.0.0.0/18"
    region                  ="europe-west1"
    network                 = google_compute_network.main.id
    private_ip_google_access= false

    secondary_ip_range {
        range_name      ="k8s-pod-range"
        ip_cidr_range   ="10.48.0.0/14"
    }

    secondary_ip_range {
        range_name      ="k8s-service-range"
        ip_cidr_range   ="10.52.0.0/14"
    }
}

#Virtual Private Network
resource "google_project_service" "compute" {
    service = "compute.googleapis.com"
}

resource "google_project_service" "container" {
    service = "container.googleapis.com"
}

resource "google_compute_network" "main" {
    name                            ="main"
    routing_mode                    ="REGIONAL"
    auto_create_subnetworks         = false
    mtu                             = 1460
    delete_default_routes_on_create = false

    depends_on = [
        google_project_service.compute,
        google_project_service.container
    ]
}


# NAT met compute address
resource "google_compute_router_nat" "nat" {
    name    ="nat"
    router  = google_compute_router.pe3router.name
    region  ="europe-west1"

    source_subnetwork_ip_ranges_to_nat  = "LIST_OF_SUBNETWORKS"
    nat_ip_allocate_option              = "MANUAL_ONLY"

    subnetwork {
        name                    = google_compute_subnetwork.private.id
        source_ip_ranges_to_nat = ["ALL_IP_RANGES"]
    }

    nat_ips = [google_compute_address.nat.self_link]
}

resource "google_compute_address" "nat" {
    name            ="nat"
    address_type    ="EXTERNAL"
    network_tier    ="STANDARD"

    depends_on = [google_project_service.compute]
}

# K8S cluster
resource "google_container_cluster" "pe3cluster"{
    name                        = "pe3cluster"
    location                    = "europe-west1"
    remove_default_node_pool    = true
    initial_node_count          = 1
    network                     = google_compute_network.main.self_link
    subnetwork                  = google_compute_subnetwork.private.self_link
    release_channel {
        channel="REGULAR"
    }
    ip_allocation_policy{
        cluster_secondary_range_name = "k8s-pod-range"
        services_secondary_range_name= "k8s-service-range"
    }
    private_cluster_config {
        enable_private_nodes    = true
        enable_private_endpoint = false
        master_ipv4_cidr_block  = "172.16.0.0/28"
    }

}


#Firewall
resource "google_compute_firewall" "pe3firewall"{
    name    ="pe3firewall"
    network = google_compute_network.main.name

    allow{
        protocol = "tcp"
        ports    = ["22"]
    }
    allow{
        protocol = "tcp"
        ports    = ["80"]
    }
    source_ranges = ["0.0.0.0/0"]
}

# Database
resource "google_sql_database_instance" "pe3database" {
  name             = "pe3database"
  database_version = "POSTGRES_15"
  region           = "europe-west1"

  settings {
    # Second-generation instance tiers are based on the machine
    # type. See argument reference below.
    tier = "db-f1-micro"
    # ip_configuration {
    #  require_ssl = true
    # }
  }
  deletion_protection = false
}


