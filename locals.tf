# Create a pseudo resource to represent the GitHub runner network
# This allows us to maintain the same reference pattern as before
locals {
  github_runner_network = {
    address_space = var.github_runner_network_address_space
    id           = var.github_runner_network_id
  }
  
  vpn_network = {
    address_space = var.vpn_network_address_space
  }
} 