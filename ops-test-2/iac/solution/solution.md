```
solution/
├── main.tf         # root, calls modules, defines terraform {} & provider
├── variables.tf    # root, defines all variables like region, instance_type, etc.
├── outputs.tf      # root, collects outputs from modules (e.g., EC2 public IP)
├── backend.tf      # optional, defines remote state (S3, etc.)
└── modules/
    ├── ec2/
    │   ├── main.tf       # defines EC2 instance using inputs (subnet_id, sg_id, ami)
    │   ├── variables.tf  # EC2-specific variables: instance_type, subnet_id, sg_id, ami
    │   └── outputs.tf    # EC2 outputs: public_ip, public_dns
    └── vpc/
        ├── main.tf       # defines VPC, subnet, IGW, route tables, SSH SG
        ├── variables.tf  # VPC-specific variables: vpc_cidr, public_subnet_cidr, az
        └── outputs.tf    # outputs subnet_id, ssh_sg_id for EC2 module

```
  
| File            | Purpose / Concern                                                                                           |
| --------------- | ----------------------------------------------------------------------------------------------------------- |
| `main.tf`       | Root entry: calls VPC and EC2 modules; don’t put resources inline here.                                     |
| `variables.tf`  | Root variables (region, instance_type, etc.) used by modules.                                               |
| `outputs.tf`    | Collect outputs from modules to see after `terraform apply`.                                                |
| `backend.tf`    | Optional: store Terraform state remotely (S3, DynamoDB lock).                                               |
| `modules/vpc/*` | Encapsulates all networking (VPC, subnet, IGW, route tables, SG). Outputs subnet and SG IDs for EC2 module. |
| `modules/ec2/*` | Encapsulates EC2 instance. Uses VPC outputs as input. Outputs public IP and DNS.                            |


# 1. Initialize Terraform (downloads providers + modules)
terraform init

# 2. See plan (what Terraform will create)
terraform plan

# 3. Apply changes (create resources)
terraform apply

# 4. Destroy resources (cleanup)
terraform destroy
