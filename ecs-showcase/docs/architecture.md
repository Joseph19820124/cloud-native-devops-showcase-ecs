# Architecture

This is the **ECS Fargate** edition of the cloud-native DevOps showcase. It runs
the exact same two-tier "hello world" app as the EKS edition, but replaces the
Kubernetes control plane and worker nodes with serverless ECS Fargate tasks.

```
                 Internet
                    │
              ┌─────▼─────┐
              │    ALB    │  (public subnets, HTTP :80)
              └─────┬─────┘
                    │ target group (ip)
          ┌─────────▼──────────┐
          │  frontend service  │  Fargate task, nginx :8080
          │  (Service Connect  │
          │      client)       │
          └─────────┬──────────┘
                    │ http://backend:5000  (Service Connect DNS)
          ┌─────────▼──────────┐
          │  backend service   │  Fargate task, gunicorn/Flask :5000
          │  (Service Connect  │
          │   server "backend")│
          └─────────┬──────────┘
                    │ :5432
              ┌─────▼─────┐
              │    RDS    │  PostgreSQL (private subnets)
              └───────────┘
```

## How this maps from the EKS version

| EKS / Kubernetes                     | ECS Fargate equivalent                          |
| ------------------------------------ | ----------------------------------------------- |
| EKS cluster + managed node group     | `aws_ecs_cluster` (FARGATE capacity providers)  |
| `Deployment`                         | `aws_ecs_task_definition` + `aws_ecs_service`   |
| Pod                                  | Fargate task (ENI in `awsvpc` mode)             |
| `Service` (ClusterIP) named backend  | ECS **Service Connect** service `backend:5000`  |
| `Ingress` / ingress-controller       | Application Load Balancer + listener            |
| `readinessProbe` / `livenessProbe`   | container `healthCheck` + ALB target-group HC   |
| `ConfigMap` / `Secret`               | task-definition `environment` (see note)        |
| `HorizontalPodAutoscaler`            | Application Auto Scaling on the ECS service      |
| requests/limits (`cpu`/`memory`)     | task `cpu` / `memory` (Fargate sizing)          |
| container images in ECR              | unchanged — same ECR repos                       |

`nginx.conf` is unchanged: it still proxies to `http://backend:5000`, because
Service Connect publishes that exact DNS name inside the cluster.

## Networking

* Custom VPC (`10.20.0.0/16`) with 2 public + 2 private subnets across 2 AZs.
* ALB lives in the public subnets; tasks run in the private subnets and reach
  ECR/RDS through a single NAT gateway. Set `assign_public_ip=true` +
  `single_nat_gateway=false` to skip the NAT gateway for a cheaper stack.

## Notes / production hardening

* The DB password is passed as a plain task `environment` variable for demo
  simplicity. In production, store it in **AWS Secrets Manager** and reference it
  via the task definition's `secrets` block instead.
* Add HTTPS (ACM cert + `:443` listener) and restrict the ALB security group.
* Turn on `db_deletion_protection` and `db_multi_az` for real environments.
