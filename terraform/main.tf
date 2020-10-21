variable "vsphere_password" {}

variable "env" {
  default = "prd"
}

provider "vsphere" {
    user                    = "administrator@vsphere.local"
    password                = var.vsphere_password
    vsphere_server          = "vc.lab.local"
    allow_unverified_ssl    = true
}

data "vsphere_datacenter" "dc" {
  name = "Lab"
}

data "vsphere_datastore" "datastore" {
  name          = "vStorage1"
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_compute_cluster" "cluster" {
  name          = "Compute"
  datacenter_id = data.vsphere_datacenter.dc.id
}
data "vsphere_network" "network" {
  name          = "Management Network"
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_virtual_machine" "template" {
  name          = "build-centos7-${var.env}"
  datacenter_id = data.vsphere_datacenter.dc.id
}

resource "vsphere_virtual_machine" "gitlab" {
  name             = "${var.env}-gitlab"
  resource_pool_id = data.vsphere_compute_cluster.cluster.resource_pool_id
  datastore_id     = data.vsphere_datastore.datastore.id

  num_cpus = 2
  memory   = 2048
  guest_id = data.vsphere_virtual_machine.template.guest_id

  scsi_type = data.vsphere_virtual_machine.template.scsi_type

  network_interface {
    network_id   = data.vsphere_network.network.id
    adapter_type = data.vsphere_virtual_machine.template.network_interface_types[0]
  }

  disk {
    label            = "disk0"
    size             = data.vsphere_virtual_machine.template.disks.0.size
    eagerly_scrub    = data.vsphere_virtual_machine.template.disks.0.eagerly_scrub
    thin_provisioned = data.vsphere_virtual_machine.template.disks.0.thin_provisioned
  }

  clone {
    template_uuid = data.vsphere_virtual_machine.template.id

    customize {
      linux_options {
        host_name = "${var.env}-gitlab"
        domain    = "lab.local"
      }

      network_interface {
        ipv4_address = "192.168.2.111"
        ipv4_netmask = 24
      }

      ipv4_gateway = "192.168.2.1"
    }
  }
}