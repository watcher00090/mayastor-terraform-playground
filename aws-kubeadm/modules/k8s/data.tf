data "null_data_source" "proto_idx_to_prefix_list" {
    inputs = {
        val = jsonencode(flatten([for item in var.worker_instances_spec : item["prefix"] ]))
    }
}

data "null_data_source" "worker_instances_spec_reordered" {
    inputs =  {
        val = jsonencode(flatten([for idx,item in var.worker_instances_spec: (index(jsondecode(data.null_data_source.proto_idx_to_prefix_list.outputs.val), item["prefix"]) != idx) ? [] : flatten([for item_prime in var.worker_instances_spec: ( item_prime["prefix"] == item["prefix"] ? [item_prime] : []) ]) ]))
    }
    depends_on = [data.null_data_source.proto_idx_to_prefix_list]
}

data "null_data_source" "idx_to_prefix_list" {
    inputs = {
        val = jsonencode(flatten([for item in jsondecode(data.null_data_source.worker_instances_spec_reordered.outputs.val) : ([for idx in range(0, parseint(lookup(item, "count", var.worker_instances_spec_default_num_workers_per_type),10)) : item["prefix"] ]) ]))
    }
    depends_on = [data.null_data_source.worker_instances_spec_reordered]
}

data "null_data_source" "idx_to_worker_type_list" {
    inputs = {
        val = jsonencode(flatten([for item in jsondecode(data.null_data_source.worker_instances_spec_reordered.outputs.val) : ([for idx in range(0, parseint(lookup(item, "count", var.worker_instances_spec_default_num_workers_per_type),10)) : lookup(item, "type", "t3.xlarge")])]))
    }
    depends_on = [data.null_data_source.worker_instances_spec_reordered]
}

data "null_data_source" "idx_to_is_mayastor_worker_list" {
  inputs = {
      val = jsonencode(flatten([for item in jsondecode(data.null_data_source.worker_instances_spec_reordered.outputs.val) : ([for idx in range(0, parseint(lookup(item, "count", var.worker_instances_spec_default_num_workers_per_type),10)) : tostring(lookup(item, "mayastor_node_label", "false"))])]))
  } 
  depends_on = [data.null_data_source.worker_instances_spec_reordered]
}

data "null_data_source" "prefix_to_count" {
    inputs = {
        val = jsonencode({for prefix in toset(jsondecode(data.null_data_source.idx_to_prefix_list.outputs.val)): 
            prefix => sum([for prefix_prime in jsondecode(data.null_data_source.idx_to_prefix_list.outputs.val): prefix_prime == prefix ? 1 : 0])
        })
    }
    depends_on = [data.null_data_source.idx_to_prefix_list]
}

data "null_data_source" "has_uuid_prefix" {
    inputs = {
        val = jsonencode({for prefix in toset(jsondecode(data.null_data_source.idx_to_prefix_list.outputs.val)):
            prefix => (0 != sum([for item in jsondecode(data.null_data_source.worker_instances_spec_reordered.outputs.val): item["prefix"] == prefix && tostring(lookup(item, "has_uuid_prefix", "__missing__")) == "true" ? 1 : 0]))
        })
    }
    depends_on = [data.null_data_source.idx_to_prefix_list, data.null_data_source.worker_instances_spec_reordered]
}

data "null_data_source" "idx_to_node_name" {
    inputs = {
        val = jsonencode([for idx in range(0,var.num_workers): (!var.use_worker_instances_spec || var.use_old_style_worker_names)? "worker-${idx+1}" : (jsondecode(data.null_data_source.prefix_to_count.outputs.val)[jsondecode(data.null_data_source.idx_to_prefix_list.outputs.val)[idx]] != 1 ? "${jsondecode(data.null_data_source.idx_to_prefix_list.outputs.val)[idx]}-${tostring(jsondecode(data.null_data_source.has_uuid_prefix.outputs.val)[jsondecode(data.null_data_source.idx_to_prefix_list.outputs.val)[idx] ] ) == "true" ? "node-" : ""}${idx - index(jsondecode(data.null_data_source.idx_to_prefix_list.outputs.val), jsondecode(data.null_data_source.idx_to_prefix_list.outputs.val)[idx]) + 1}" : "${jsondecode(data.null_data_source.idx_to_prefix_list.outputs.val)[idx]}") ])
    }
    depends_on = [data.null_data_source.prefix_to_count, data.null_data_source.idx_to_prefix_list]
}