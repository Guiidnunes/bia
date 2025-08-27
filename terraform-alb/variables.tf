# Variáveis para o Terraform do ALB - Projeto BIA

variable "aws_region" {
  description = "Região AWS onde os recursos serão criados"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Nome do projeto (usado como prefixo nos recursos)"
  type        = string
  default     = "bia"
}

variable "vpc_id" {
  description = "ID da VPC onde o ALB será criado"
  type        = string
  default     = "vpc-02e84025586853660"
}

variable "subnet_ids" {
  description = "IDs das subnets públicas para o ALB"
  type        = list(string)
  default     = [
    "subnet-0395ba334c798fb73",  # us-east-1a
    "subnet-0d3243c9860da1887"   # us-east-1b
  ]
}

variable "certificate_arn" {
  description = "ARN do certificado SSL/TLS do ACM"
  type        = string
  default     = "arn:aws:acm:us-east-1:098978302313:certificate/3261de3b-8109-4cfd-8cde-86139d04af2e"
}
