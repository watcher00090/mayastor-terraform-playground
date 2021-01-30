resource "google_compute_firewall" "allow_egress" {
  name          = "allow-egress"
  network       = google_compute_network.main.name
  source_ranges = ["0.0.0.0/0"]

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    ports    = ["80", "8080", "1000-2000", "22", "6443", "3389"]
  }
}

resource "google_compute_firewall" "allow_internal_traffic" {
  name          = "allow-internal-traffic"
  network       = google_compute_network.main.name
  source_ranges = [var.gcp_address_cidr_block]

  allow {
    protocol = "all"
  }
}

resource "google_compute_firewall" "allow_internal_traffic_pods" {
  name          = "allow-internal-traffic-pods"
  network       = google_compute_network.main.name
  source_ranges = [local.flannel_cidr]

  allow {
    protocol = "all"
  }
}

resource "google_compute_subnetwork" "main" {
  name          = "main"
  ip_cidr_range = var.gcp_address_cidr_block
  region        = "us-central1"
  network       = google_compute_network.main.id
  #secondary_ip_range {
  #  range_name    = "subnetwork-1-secondary-range"
  #  ip_cidr_range = "192.168.10.0/24"
  #}
}

resource "google_compute_network" "main" {
  name                    = "main"
  auto_create_subnetworks = false
}