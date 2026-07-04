# Architecture

This is the **ECS Fargate** edition of the cloud-native DevOps showcase. It runs
the exact same two-tier "hello world" app as the EKS edition, but replaces the
Kubernetes control plane and worker nodes with serverless ECS Fargate tasks.

Both services are published through **one ALB** with path-based routing — the
ECS equivalent of a Kubernetes Ingress fanning out to two Services:

```
                        Internet / browser
                              │  HTTP :80
                        ┌─────▼─────┐
                        │    ALB    │  (public subnets)
                        └─────┬─────┘
              path routing on the :80 listener
        ┌───────────────────┴────────────────────┐
    default │ "/"                       "/api/*", "/health" │
   ┌────────▼─────────┐                 ┌──────────▼─────────┐
   │ frontend TG      │                 │ backend TG         │
   │ frontend service │                 │ backend service    │
   │ nginx :8080      │                 │ gunicorn/Flask :5000│
   │ (static site)    │                 └──────────┬─────────┘
   └──────────────────┘                            │ :5432
                                             ┌──────▼──────┐
                                             │    RDS      │ (private subnets)
                                             └─────────────┘
```

The frontend is a **static** site; the browser calls `/api/...` on the same ALB
host and the ALB routes it straight to the backend target group. There is no
service-to-service (Service Connect) hop — frontend↔backend goes through the ALB,
exactly like both Services sitting behind one Ingress.

## How this maps from the EKS version

| EKS / Kubernetes                     | ECS Fargate equivalent                          |
| ------------------------------------ | ----------------------------------------------- |
| EKS cluster + managed node group     | `aws_ecs_cluster` (FARGATE capacity providers)  |
| `Deployment`                         | `aws_ecs_task_definition` + `aws_ecs_service`   |
| Pod                                  | Fargate task (ENI in `awsvpc` mode)             |
| `Ingress` fan-out (`/` and `/api`)   | **ALB listener + path rules → 2 target groups** |
| `Service` (frontend / backend)       | ALB target group per service                    |
| `readinessProbe` / `livenessProbe`   | container `healthCheck` + ALB target-group HC   |
| `ConfigMap` / `Secret`               | task-definition `environment` (see note)        |
| `HorizontalPodAutoscaler`            | Application Auto Scaling on the ECS service      |
| requests/limits (`cpu`/`memory`)     | task `cpu` / `memory` (Fargate sizing)          |
| container images in ECR              | unchanged — same ECR repos                       |

Because the ALB owns the `/api` routing, `nginx.conf` is a plain static-file
server — it no longer proxies to the backend.

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
