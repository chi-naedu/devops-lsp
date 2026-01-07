# 1. Subnet Group (Place Redis in Private Subnets)
resource "aws_elasticache_subnet_group" "linksnap_redis_subnet" {
  name       = "linksnap-redis-subnet"
  subnet_ids = [
    aws_subnet.private_subnet_1.id,
    aws_subnet.private_subnet_2.id
  ]
}

# 2. Security Group (Allow access only from EKS nodes)
resource "aws_security_group" "redis_sg" {
  name        = "linksnap-redis-sg"
  description = "Allow EKS to talk to Redis"
  vpc_id      = aws_vpc.main_vpc.id

  ingress {
    from_port       = 6379
    to_port         = 6379
    protocol        = "tcp"
    # Allow traffic ONLY from the Kubernetes Worker Nodes
    security_groups = [module.eks.node_security_group_id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# 3. The Redis Cluster (Primary DB)
resource "aws_elasticache_replication_group" "linksnap_redis" {
  replication_group_id       = "linksnap-db"
  description                = "Primary Database for LinkSnap"
  node_type                  = "cache.t3.micro"
  port                       = 6379
  parameter_group_name       = "default.redis7"
  
  # Single node for cost efficiency (add replicas for production)
  num_node_groups         = 1
  replicas_per_node_group = 0 
  
  subnet_group_name  = aws_elasticache_subnet_group.linksnap_redis_subnet.name
  security_group_ids = [aws_security_group.redis_sg.id]

  # Persistence / Backup settings
  snapshot_retention_limit = 1 # Keep daily backups (Critical since this is a DB)
  snapshot_window          = "05:00-06:00"
}

# 4. Output the Endpoint
output "redis_endpoint" {
  value = aws_elasticache_replication_group.linksnap_redis.primary_endpoint_address
}