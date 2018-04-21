provider "google" {
  credentials = "${file("~/.gcloud/account.json")}"
  project     = "teamspeak"
  region      = "europe-west1"
  zone        = "europe-west1-c"
}

resource "google_compute_disk" "teamspeak_disk" {
  name = "teamspeak-disk"
  type = "pd-standard"
  size = "10"
}

resource "google_compute_instance" "teamspeak" {
  name         = "teamspeak-micro"
  machine_type = "f1-micro"

  boot_disk {
    initialize_params {
      image = "debian-9"
    }
  }

  network_interface {
    network       = "default"
    access_config = {}
  }

  tags = ["teamspeak"]

  allow_stopping_for_update = true

  scheduling {
    preemptible         = false
    on_host_maintenance = "MIGRAGE"
    automatic_restart   = true
  }

  attached_disk {
    source = "${google_compute_disk.teamspeak_disk.self_link}"
  }
}

data "google_dns_managed_zone" "julian_schwing" {
  "name" = "julian-schwing"
}

resource "google_dns_record_set" "teamspeak" {
  name = "${data.google_dns_managed_zone.julian_schwing.dns_name}"
}
