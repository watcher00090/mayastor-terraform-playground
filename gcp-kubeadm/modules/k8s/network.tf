resource "google_compute_firewall" "firewall_1" {
  name    = "firewall-1"
  network = google_compute_network.network_1.name
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
    name = "allow-internal-traffic-firewall"
    network = google_compute_network.network_1.name
    source_ranges = ["10.128.0.0/9"]

    allow {
        protocol = "tcp"
        ports = ["0-65535"]
    }

    allow {
        protocol = "udp"
        ports = ["0-65535"]
    }

    allow {
        protocol = "icmp"
    }
}

resource "google_compute_subnetwork" "subnetwork_1" {
  name          = "subnetwork-1"
  ip_cidr_range = "10.128.0.0/16"
  region        = "us-central1"
  network       = google_compute_network.network_1.id
  secondary_ip_range {
    range_name    = "subnetwork-1-secondary-range"
    ip_cidr_range = "192.168.10.0/24"
  }
}

resource "google_compute_network" "network_1" {
  name                    = "network-1"
  auto_create_subnetworks = false
}