# Configurações específicas do ambiente BIA
# Baseado na infraestrutura atual em produção

aws_region = "us-east-1"
project_name = "bia"
vpc_id = "vpc-02e84025586853660"

subnet_ids = [
  "subnet-0395ba334c798fb73",  # us-east-1a
  "subnet-0d3243c9860da1887"   # us-east-1b
]

certificate_arn = "arn:aws:acm:us-east-1:098978302313:certificate/3261de3b-8109-4cfd-8cde-86139d04af2e"
