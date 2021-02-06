output "num_workers" {
    value = !var.use_worker_instances_spec ? var.num_workers : sum([for item in var.worker_instances_spec : parseint(lookup(item, "count", var.worker_instances_spec_default_num_workers_per_type),10)])
}

output "worker_instances_spec" {
    value = [for item in var.worker_instances_spec: ((tostring(lookup(item, "mayastor_node_label", "__missing__")) == "true") ? merge(item,{prefix="mayastor-worker"}) : (lookup(item, "prefix", "__missing__") == "__missing__" ? merge(item,{prefix="${substr(uuid(),0,var.num_chars_for_group_identifier)}", has_uuid_prefix = "true"}) : item))]
}

output "num_mayastor_workers" {
    value = sum(flatten([for item in var.worker_instances_spec: [for idx in range(0,parseint(lookup(item, "count", var.worker_instances_spec_default_num_workers_per_type),10)): tostring(lookup(item, "mayastor_node_label", "__missing__")) == "true" ? 1 : 0 ]]))
}