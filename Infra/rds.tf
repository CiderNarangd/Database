terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = "ap-northeast-2" 
}

# -------------------------------------------------------------
# 1. AWS 기본 네트워크(VPC 및 서브넷) 정보 자동 조회
# -------------------------------------------------------------

data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# -------------------------------------------------------------
# 2. RDS 전용 보안 그룹 (외부 접속 허용 설정)
# -------------------------------------------------------------

resource "aws_security_group" "rds_sg" {
  name        = "standalone-rds-sg"
  description = "Test Server"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] 
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# -------------------------------------------------------------
# 3. RDS 서브넷 그룹 정의
# -------------------------------------------------------------
resource "aws_db_subnet_group" "rds_subnet_group" {
  name       = "standalone-rds-subnet-group"
  subnet_ids = data.aws_subnets.default.ids
}

# -------------------------------------------------------------
# 4. AWS RDS MySQL 단독 인스턴스 배포 (프리티어)
# -------------------------------------------------------------

resource "aws_db_instance" "mysql_db" {
  identifier            = "my-free-mysql-db"

  allocated_storage     = 20              
  max_allocated_storage = 20               
  engine                = "mysql"
  engine_version        = "8.4.8"            
  instance_class        = "db.t4g.micro"   

  db_name               = "testdb"        
  username              = "admin"          
  password              = "kinam12##" 

  db_subnet_group_name   = aws_db_subnet_group.rds_subnet_group.name
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  
  publicly_accessible   = true             

  skip_final_snapshot   = true 
}

# -------------------------------------------------------------
# 5. 배포 완료 후 결과물 출력
# -------------------------------------------------------------

output "rds_endpoint" {
  value       = aws_db_instance.mysql_db.endpoint
  description = "RDS MySQL 접속 주소"
}