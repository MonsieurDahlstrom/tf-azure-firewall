# Basic Azure Firewall Example

This example demonstrates the simplest possible deployment of Azure Firewall using the Hub Virtual Network approach.

## What this example creates

- A resource group
- A hub virtual network (10.0.0.0/16)
- An Azure Firewall with:
  - Standard SKU
  - Single public IP
  - Threat intelligence enabled
  - Basic logging to Log Analytics

## Usage

1. Clone this repository
2. Navigate to this example directory
3. Initialize Terraform:
   ```bash
   terraform init
   ```
4. Plan the deployment:
   ```bash
   terraform plan
   ```
5. Apply the configuration:
   ```bash
   terraform apply
   ```

## Customization

You can customize the deployment by modifying the variables in `terraform.tfvars`:

```hcl
resource_group_name = "my-firewall-rg"
location           = "westeurope"
environment        = "prod"
project_name       = "myproject"
firewall_sku_tier  = "Premium"  # or "Basic", "Standard"
```

## Outputs

The example outputs the essential information you need:
- Firewall ID and name
- Private and public IP addresses
- Hub virtual network ID

## Next Steps

After deploying this basic firewall, you can:
1. Peer spoke virtual networks to the hub VNet
2. Configure User Defined Routes (UDRs) to route traffic through the firewall
3. Add custom firewall rules using the module's advanced features
4. Connect to Virtual WAN (if needed)

## Clean Up

To remove all resources:
```bash
terraform destroy
``` 