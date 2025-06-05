# Generic CIDR-Based Firewall Policy Configuration

This document provides examples of how to use the policy-driven firewall configuration based on CIDR ranges and egress policies.

## Network Groups

Define network groups with their CIDR ranges:

```hcl
network_groups = {
  "development" = {
    name             = "development-networks"
    address_prefixes = ["10.163.0.0/18"]
    description      = "Development environment networks"
  }
  "staging" = {
    name             = "staging-networks"
    address_prefixes = ["10.162.0.0/18"]
    description      = "Staging environment networks"
  }
  "production" = {
    name             = "production-networks"
    address_prefixes = ["10.161.0.0/18"]
    description      = "Production environment networks"
  }
  "github_runners" = {
    name             = "github-runner-networks"
    address_prefixes = ["10.100.0.0/24"]
    description      = "GitHub runner networks"
  }
}
```

## Network Policies - CIDR-Based Egress Control

The firewall uses a policy-driven approach where different CIDR ranges get different egress behaviors:

### Available Egress Policies

1. **`allow_all_logged`** - Allow all traffic but log everything (Development)
2. **`explicit_allow_only`** - Only allow explicitly specified destinations (Staging/Production)  
3. **`deny_all`** - Block all traffic (Restricted environments)

### Development Environment - Allow All with Logging

```hcl
network_policies = {
  "development" = {
    network_group_keys = ["development", "github_runners"]
    egress_policy      = "allow_all_logged"
    priority_base      = 200
    description        = "Development environment - allow all traffic but log everything"
  }
}
```

**Behavior**: 
- ✅ All HTTP/HTTPS traffic allowed
- ✅ All network traffic allowed  
- 📊 Everything is logged for monitoring
- 🎯 Perfect for development where you need unrestricted access

### Staging Environment - Explicit Allow Only

```hcl
network_policies = {
  "staging" = {
    network_group_keys = ["staging"]
    egress_policy      = "explicit_allow_only"
    priority_base      = 300
    description        = "Staging environment - only allow specified destinations"
    allowed_destinations = {
      fqdns = [
        "github.com",
        "*.github.com",
        "mcr.microsoft.com",
        "*.azure.com",
        "api.example.com"
      ]
      addresses = ["8.8.8.8", "1.1.1.1"]  # DNS servers
      ports     = ["443", "80", "53"]
      protocols = ["TCP", "UDP"]
    }
    blocked_destinations = {
      fqdns = ["*.malicious.com", "blocked-site.com"]
      ports = ["443", "80"]
    }
  }
}
```

**Behavior**:
- ✅ Only specified FQDNs/IPs allowed
- ❌ All other traffic blocked
- 🚫 Explicitly blocked destinations have higher priority
- 📊 All traffic logged

### Production Environment - Strict Control

```hcl
network_policies = {
  "production" = {
    network_group_keys = ["production"]
    egress_policy      = "explicit_allow_only"
    priority_base      = 400
    description        = "Production environment - minimal required access only"
    allowed_destinations = {
      fqdns = [
        "api.essential-service.com",
        "*.vault.azure.net",
        "*.servicebus.windows.net"
      ]
      addresses = ["10.200.1.10"]  # Internal service
      ports     = ["443"]
      protocols = ["TCP"]
    }
  }
}
```

### Restricted Environment - Deny All

```hcl
network_policies = {
  "isolated" = {
    network_group_keys = ["isolated_network"]
    egress_policy      = "deny_all"
    priority_base      = 500
    description        = "Completely isolated environment"
  }
}
```

**Behavior**:
- ❌ All traffic blocked
- 📊 All blocked attempts logged
- 🔒 Maximum security for sensitive workloads

## Default Egress Policy

Configure the catch-all rule for traffic not matching any specific policy:

```hcl
default_egress_policy = {
  action      = "Deny"     # Block everything by default
  priority    = 900        # Lowest priority (last rule)
  log_traffic = true       # Log all blocked traffic
  description = "Default deny all for security"
}
```

## Complete Example - Multi-Environment Setup

```hcl
module "firewall" {
  source = "./modules/firewall"

  # Basic configuration
  resource_group_name     = "rg-hub-networking"
  location               = "West Europe"
  virtual_hub_id         = "/subscriptions/.../virtualHubs/hub-westeurope"
  dns_resolver_private_ip = "10.160.0.4"
  
  # Legacy variables (still required for basic firewall setup)
  github_runner_network_address_space = ["10.100.0.0/24"]
  github_runner_network_id           = "/subscriptions/.../virtualNetworks/vnet-github-runners"
  vpn_network_address_space          = "10.150.0.0/24"

  # Define network groups
  network_groups = {
    "dev" = {
      name             = "development-networks"
      address_prefixes = ["10.163.0.0/18"]
      description      = "Development environment"
    }
    "staging" = {
      name             = "staging-networks"  
      address_prefixes = ["10.162.0.0/18"]
      description      = "Staging environment"
    }
    "prod" = {
      name             = "production-networks"  
      address_prefixes = ["10.161.0.0/18"]
      description      = "Production environment"
    }
  }

  # Environment-specific policies
  network_policies = {
    "development" = {
      network_group_keys = ["dev"]
      egress_policy      = "allow_all_logged"
      priority_base      = 200
      description        = "Dev env - allow all, log everything"
    }
    
    "staging" = {
      network_group_keys = ["staging"]
      egress_policy      = "explicit_allow_only"
      priority_base      = 300
      description        = "Staging env - controlled access"
      allowed_destinations = {
        fqdns = [
          "github.com", "*.github.com",
          "mcr.microsoft.com",
          "*.vault.azure.net"
        ]
        ports = ["443"]
      }
    }
    
    "production" = {
      network_group_keys = ["prod"]
      egress_policy      = "explicit_allow_only"
      priority_base      = 400
      description        = "Prod env - minimal access"
      allowed_destinations = {
        fqdns = [
          "api.essential-service.com",
          "*.servicebus.windows.net"
        ]
        ports = ["443"]
      }
    }
  }

  # Default deny all unmatched traffic
  default_egress_policy = {
    action      = "Deny"
    priority    = 900
    log_traffic = true
  }

  # Custom rules for specific needs
  custom_application_rules = {
    "admin_access" = {
      name     = "admin-access"
      priority = 150  # Higher priority than policies
      action   = "Allow"
      rules = [
        {
          name             = "admin-console-access"
          source_addresses = ["10.200.0.0/24"]  # Admin network
          destination_fqdns = ["admin.company.com"]
          protocols = [{ port = "443", type = "Https" }]
        }
      ]
    }
  }

  tags = {
    Environment = "Hub"
    Purpose     = "Networking"
  }
}
```

## Policy Priority Strategy

The firewall evaluates rules in priority order (lower number = higher priority):

```
100-149: Custom NAT rules
150-199: Custom high-priority application rules  
200-299: Development policies (allow_all_logged)
300-399: Staging policies (explicit_allow_only)
400-499: Production policies (explicit_allow_only)
500-599: Restricted policies (deny_all)
600-799: Custom application/network rules
800-899: Security and compliance rules
900-999: Default egress policy (catch-all)
```

## Architecture Benefits

### **Environment-Based Control**
- **Development**: Full access with logging for debugging
- **Staging**: Controlled access to test real-world restrictions
- **Production**: Minimal access for maximum security
- **Isolated**: Complete lockdown for sensitive workloads

### **Default Deny Security**
- All traffic denied by default at priority 900
- Only explicitly allowed traffic passes through
- Every policy must be intentional

### **Comprehensive Logging**
- All traffic logged regardless of policy
- Blocked traffic logged for security monitoring
- Easy to track what's being accessed from each environment

### **Flexible Overrides**
- Custom rules can override policies with higher priority
- Emergency access rules can be added quickly
- Gradual policy rollout possible

## Migration Strategy

1. **Start with `allow_all_logged`** for all environments
2. **Monitor logs** to understand traffic patterns
3. **Create explicit allow lists** based on actual usage
4. **Switch to `explicit_allow_only`** for staging first
5. **Roll out to production** after validation
6. **Implement `deny_all`** for isolated workloads

This approach gives you **security by default** with **flexibility per environment**! 🔒 