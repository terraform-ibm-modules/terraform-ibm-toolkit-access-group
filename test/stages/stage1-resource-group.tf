module "resource_groups" {
  source = "github.com/ibm-garage-cloud/terraform-ibm-resource-group.git?ref=main"

  resourceGroupNames = var.new_resource_group
}
