resource "random_password" "k3s_token" {
  length  = 48
  special = false
}

resource "hcloud_ssh_key" "default" {
  name       = var.my_public_ssh_name
  public_key = var.my_public_ssh_key
}
