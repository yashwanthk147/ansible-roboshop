#iterate on modules rather than individual resources
module "ec2" {
    for_each = var.instance
    source = "./ec2"
    component = each.value["name"]
    instance_type = each.value["type"]
  
}

module "sg" {
    for_each = var.instance
    source = "./sg"
}


module "route53" {
    for_each = var.instance
    source = "./route53"
    component = each.value["name"]
  
}

