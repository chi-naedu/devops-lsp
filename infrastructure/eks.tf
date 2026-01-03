module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = "linksnap-cluster"
  cluster_version = "1.30"

  # This connects the cluster to your existing VPC
  vpc_id                   = aws_vpc.main_vpc.id
  subnet_ids = [
    aws_subnet.private_subnet_1.id,
    aws_subnet.private_subnet_2.id
  ]

  control_plane_subnet_ids = [
    aws_subnet.public_subnet_1.id,
    aws_subnet.public_subnet_2.id
  ]

  # Security: Allow public access to the API server (so you can run kubectl from your laptop)
  cluster_endpoint_public_access = true

  # Grant your current user admin permissions (so you can manage the cluster)
  enable_cluster_creator_admin_permissions = true

  # --- The Worker Nodes (Where your app runs) ---
  eks_managed_node_groups = {
    main_nodes = {
      # t3.medium is the "sweet spot" for k8s (2 vCPU, 4GB RAM).
      # t3.micro is too small (system pods will crash).
      instance_types = ["t3.medium"]
      
      min_size     = 2
      max_size     = 3
      desired_size = 2
      
      # Disk size for the nodes
      disk_size = 20
    }
  }

  tags = {
    Environment = "Production"
    Project     = "LinkSnap"
  }
}

# --- Output the Cluster Name ---
output "cluster_endpoint" {
  description = "Endpoint for EKS control plane"
  value       = module.eks.cluster_endpoint
}

output "cluster_name" {
  description = "Kubernetes Cluster Name"
  value       = module.eks.cluster_name
}