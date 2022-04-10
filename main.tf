
/*** Create Access Groups for Admins and Users ***/
locals {
  roles = ["admin", "edit", "view"]
}

module "clis" {
  source = "github.com/cloud-native-toolkit/terraform-util-clis.git"

  clis = ["jq"]
}

resource "null_resource" "print_names" {
  provisioner "local-exec" {
    command = "echo 'Resource group: ${var.resource_group_name}'"
  }
}

resource "random_uuid" "tag" {
}


resource null_resource create_access_groups {
  count = length(local.roles)

  triggers = {
    bin_dir        = module.clis.bin_dir
    description    = "${local.roles[count.index]} group for ${var.resource_group_name} [${random_uuid.tag.result}]"
    group          = upper("${replace(var.resource_group_name, "-", "_")}_${local.roles[count.index]}")
    ibmcloud_api_key = base64encode(var.ibmcloud_api_key)
  }

  provisioner "local-exec" {
    command = "${path.module}/scripts/create-access-group.sh ${self.triggers.group} '${self.triggers.description}'"

    environment = {
      BIN_DIR = self.triggers.bin_dir
      IBMCLOUD_API_KEY = base64decode(self.triggers.ibmcloud_api_key)
    }
  }

  provisioner "local-exec" {
    when = destroy
    command = "${path.module}/scripts/delete-access-group.sh ${self.triggers.group} '${self.triggers.description}'"

    environment = {
      BIN_DIR = self.triggers.bin_dir
      IBMCLOUD_API_KEY = base64decode(self.triggers.ibmcloud_api_key)
    }
  }
}

data ibm_resource_group resource_group {
  depends_on = [null_resource.print_names]

  name = var.resource_group_name
}

data ibm_iam_access_group admins {
  depends_on = [null_resource.create_access_groups]

  access_group_name = upper("${replace(var.resource_group_name, "-", "_")}_${local.roles[0]}")
}

data ibm_iam_access_group editors {
  depends_on = [null_resource.create_access_groups]

  access_group_name = upper("${replace(var.resource_group_name, "-", "_")}_${local.roles[1]}")
}

data ibm_iam_access_group viewers {
  depends_on = [null_resource.create_access_groups]

  access_group_name = upper("${replace(var.resource_group_name, "-", "_")}_${local.roles[2]}")
}

/*** Import resource groups for the Admins Access Groups ***/

/*** Admins Access Groups Policies ***/

#resource ibm_iam_access_group_policy admin_policy_1 {
#  access_group_id = data.ibm_iam_access_group.admins.id
#  roles           = ["Editor", "Manager"]
#
#  resources {
#    resource_group_id = data.ibm_resource_group.resource_group.id
#  }
#}


resource "null_resource" "print_access_group_id" {
  provisioner "local-exec" {
    command = "echo 'Access group: ${data.ibm_iam_access_group.admins.access_group_name} ${data.ibm_iam_access_group.admins.groups.0.id}'"
  }
}
resource null_resource admin_policy_1 {

  triggers = {
    bin_dir        = module.clis.bin_dir
    access_group_id = data.ibm_iam_access_group.admins.groups.0.id
    description    = "admin_policy_1 group for ${data.ibm_iam_access_group.admins.id} [${random_uuid.tag.result}]"
    ibmcloud_api_key = base64encode(var.ibmcloud_api_key)
    attributes = "{ \"name\": \"resourceGroupId\", \"value\": \"${data.ibm_resource_group.resource_group.id}\" }"
  }

  provisioner "local-exec" {
    command = "${path.module}/scripts/create-access-group-policy.sh"

    environment = {
      BIN_DIR = self.triggers.bin_dir
      IBMCLOUD_API_KEY = base64decode(self.triggers.ibmcloud_api_key)
      ACCESS_GROUP_ID = self.triggers.access_group_id
      DESCRIPTION = self.triggers.description
      RESOURCE_ATTRIBUTES = self.triggers.attributes
    }
  }

  provisioner "local-exec" {
    when = destroy
    command = "${path.module}/scripts/delete-access-group-policy.sh"

    environment = {
      BIN_DIR = self.triggers.bin_dir
      IBMCLOUD_API_KEY = base64decode(self.triggers.ibmcloud_api_key)
      ACCESS_GROUP_ID = self.triggers.access_group_id
      DESCRIPTION = self.triggers.description
      RESOURCE_ATTRIBUTES = self.triggers.attributes
    }
  }
}





#
#resource ibm_iam_access_group_policy admin_policy_2 {
#  access_group_id = data.ibm_iam_access_group.admins.id
#  roles           = ["Viewer"]
#
#  resources {
#    resource_group_id = data.ibm_resource_group.resource_group.id
#    attributes        = { "resourceType" = "resource-group", "resource" = var.resource_group_name }
#  }
#}
#
#resource ibm_iam_access_group_policy admin_policy_3 {
#  access_group_id = data.ibm_iam_access_group.admins.id
#  roles           = ["Administrator", "Manager"]
#
#  resources {
#    service           = "containers-kubernetes"
#    resource_group_id = data.ibm_resource_group.resource_group.id
#  }
#}
#
#resource ibm_iam_access_group_policy admin_policy_4 {
#  access_group_id = data.ibm_iam_access_group.admins.id
#  roles           = ["Administrator", "Manager"]
#
#  resources {
#    service = "container-registry"
#  }
#}
#
#/*** Editor Access Groups Policies ***/
#
#resource ibm_iam_access_group_policy edit_policy_1 {
#  access_group_id = data.ibm_iam_access_group.editors.id
#  roles           = ["Viewer", "Manager"]
#
#  resources {
#    resource_group_id = data.ibm_resource_group.resource_group.id
#  }
#}
#
#resource ibm_iam_access_group_policy edit_policy_2 {
#  access_group_id = data.ibm_iam_access_group.editors.id
#  roles           = ["Viewer"]
#
#  resources {
#    resource_group_id = data.ibm_resource_group.resource_group.id
#    attributes        = { "resourceType" = "resource-group", "resource" = var.resource_group_name }
#  }
#}
#
#resource ibm_iam_access_group_policy edit_policy_3 {
#  access_group_id = data.ibm_iam_access_group.editors.id
#  roles           = ["Editor", "Writer"]
#
#  resources {
#    service           = "containers-kubernetes"
#    resource_group_id = data.ibm_resource_group.resource_group.id
#  }
#}
#
#resource ibm_iam_access_group_policy edit_policy_4 {
#  access_group_id = data.ibm_iam_access_group.editors.id
#  roles           = ["Reader", "Writer"]
#
#  resources {
#    resource_type     = "namespace"
#    resource_group_id = data.ibm_resource_group.resource_group.id
#    service           = "container-registry"
#  }
#}
#
#
#/*** Viewer Access Groups Policies ***/
#
#resource ibm_iam_access_group_policy view_policy_1 {
#  access_group_id = data.ibm_iam_access_group.viewers.id
#  roles           = ["Viewer", "Reader"]
#
#  resources {
#    resource_group_id = data.ibm_resource_group.resource_group.id
#  }
#}
#
#resource ibm_iam_access_group_policy view_policy_2 {
#  access_group_id = data.ibm_iam_access_group.viewers.id
#  roles           = ["Viewer"]
#
#  resources {
#    resource_group_id = data.ibm_resource_group.resource_group.id
#    attributes        = { "resourceType" = "resource-group", "resource" = var.resource_group_name }
#  }
#}
#
#resource ibm_iam_access_group_policy view_policy_3 {
#  access_group_id = data.ibm_iam_access_group.viewers.id
#  roles           = ["Viewer", "Reader"]
#
#  resources {
#    service           = "containers-kubernetes"
#    resource_group_id = data.ibm_resource_group.resource_group.id
#  }
#}
#
#resource ibm_iam_access_group_policy view_policy_4 {
#  access_group_id = data.ibm_iam_access_group.viewers.id
#  roles           = ["Viewer", "Reader"]
#
#  resources {
#    resource_type     = "namespace"
#    resource_group_id = data.ibm_resource_group.resource_group.id
#    service           = "container-registry"
#  }
#}
