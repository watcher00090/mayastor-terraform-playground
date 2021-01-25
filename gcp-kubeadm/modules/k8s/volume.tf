resource "google_compute_disk" "mayastor" {
  count = length(google_compute_instance.node)
  name  = "mayastor-${google_compute_instance.node[count.index].name}"
  size  = 30 # 30GB
}

resource "google_compute_attached_disk" "disk_attacher" {
  count    = length(google_compute_instance.node)
  instance = google_compute_instance.node[count.index].id
  disk     = google_compute_disk.mayastor[count.index].id
}