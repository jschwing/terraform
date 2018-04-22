provider "google" {
  credentials = "${file("~/.gcloud/account.json")}"
  project     = "teamspeak-201815"
  region      = "europe-west1"
  zone        = "europe-west1-c"
}

data "google_dns_managed_zone" "julian_schwing" {
  "name" = "julian-schwing"
}

resource "google_compute_address" "teamspeak_ip" {
  name = "teamspeak-ip"
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
    network = "default"

    access_config {
      nat_ip = "${google_compute_address.teamspeak_ip.address}"
    }
  }

  tags = ["teamspeak"]

  allow_stopping_for_update = true

  scheduling {
    preemptible         = false
    on_host_maintenance = "MIGRATE"
    automatic_restart   = true
  }

  attached_disk {
    source = "${google_compute_disk.teamspeak_disk.self_link}"
  }

  metadata {
    ssh-keys = "julianschwing:${chomp(file("~/.gcloud/id_rsa.pub"))}"
  }
}

resource "google_dns_record_set" "teamspeak" {
  name = "${data.google_dns_managed_zone.julian_schwing.dns_name}"
  type = "A"
  ttl  = 86400

  managed_zone = "${data.google_dns_managed_zone.julian_schwing.name}"

  rrdatas = ["${google_compute_address.teamspeak_ip.address}"]

  depends_on = [
    "google_compute_address.teamspeak_ip",
  ]
}

resource "google_compute_firewall" "teamspeak_voice" {
  name = "teamspeak-voice"

  network = "default"

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["teamspeak"]

  allow {
    protocol = "udp"
    ports    = ["9987"]
  }
}

resource "google_compute_firewall" "teamspeak_file" {
  name = "teamspeak-file"

  network = "default"

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["teamspeak"]

  allow {
    protocol = "tcp"
    ports    = ["30033"]
  }
}

resource "google_compute_firewall" "teamspeak_server_query" {
  name = "teamspeak-server-query"

  network = "default"

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["teamspeak"]

  allow {
    protocol = "tcp"
    ports    = ["10011"]
  }
}

resource "google_compute_firewall" "teamspeak_tsdns" {
  name = "teamspeak-tsdns"

  network = "default"

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["teamspeak"]

  allow {
    protocol = "tcp"
    ports    = ["41144"]
  }
}

resource "null_resource" "setup" {
  triggers {
    instance = "${google_compute_instance.teamspeak.self_link}"
    disk     = "${google_compute_disk.teamspeak_disk.self_link}"
  }

  connection {
    host        = "${google_compute_address.teamspeak_ip.address}"
    type        = "ssh"
    user        = "julianschwing"
    private_key = "${chomp(file("~/.gcloud/id_rsa"))}"
  }

  provisioner "file" {
    source      = "create_volumes.sh"
    destination = "/tmp/create_volumes.sh"
  }

  provisioner "file" {
    source      = "add_teamspeak_user.sh"
    destination = "/tmp/add_teamspeak_user.sh"
  }

  provisioner "file" {
    source      = "create_teamspeak_service.sh"
    destination = "/tmp/create_teamspeak_service.sh"
  }

  provisioner "remote-exec" {
    # Bootstrap script called with private_ip of each node in the clutser
    inline = [
      "sudo bash /tmp/create_volumes.sh",
      "sudo adduser teamspeak --system --home /data/teamspeak3-server_linux_amd64 --disabled-login",
      "sudo apt-get install bzip2",
      "sudo -u teamspeak bash /tmp/add_teamspeak_user.sh",
      "sudo bash /tmp/create_teamspeak_service.sh",
      "rm -rf /tmp/*.sh",
    ]
  }
}
