# Cloud Native DevOps Showcase — ECS Fargate edition

A small, end-to-end "hello world" web app (nginx frontend + Flask/PostgreSQL
backend) deployed on **AWS ECS Fargate** with Terraform. It is a port of the
[EKS-based showcase](https://github.com/Joseph19820124/cloud-native-devops-showcase)
to serverless containers — same app, no Kubernetes.

> Looking for the mapping from Kubernetes objects to ECS resources? See
> [`ecs-showcase/docs/architecture.md`](ecs-showcase/docs/architecture.md).

## What's inside

```
ecs-showcase/
├── app/
│   ├── backend/      Flask + gunicorn API, talks to PostgreSQL
│   └── frontend/     nginx serving static HTML, proxies /api → backend:5000
├── terraform/
│   ├── modules/
│   │   ├── network/  VPC, public/private subnets, NAT gateway
│   │   ├── ecr/      container registries (frontend, backend)
│   │   ├── alb/      Application Load Balancer + target group + listener
│   │   ├── ecs/      Fargate cluster, task defs, services, Service Connect
│   │   ├── rds/      PostgreSQL
│   │   └── s3/       demo bucket
│   └── environments/dev/   root module wiring it all together
├── scripts/          deploy.sh · build-and-push.sh · destroy.sh
├── ecs/              where to keep exported task-definition JSON (optional)
├── docs/             architecture + EKS→ECS mapping
└── .github/workflows CI (tests, build, tf validate) + manual deploy
```

## Architecture

```
Internet / browser → ALB (:80, public subnets)  ── path routing ──┐
                        │ "/"                        "/api/*","/health"
              frontend TG → nginx :8080        backend TG → gunicorn :5000
              (static site)                                    → RDS (:5432, private)
```

Both services sit behind **one ALB** with path-based routing — the ECS analog of
a Kubernetes Ingress fanning out to two Services. The frontend is static; the
browser calls `/api/...` on the same ALB host and the ALB sends it straight to
the backend target group (no Service Connect hop).

## Deploy

Prereqs: Terraform ≥ 1.6, Docker, AWS CLI with credentials for the target
account.

```bash
cd ecs-showcase
export AWS_PROFILE=your-profile          # e.g. aws-10
export TF_VAR_db_password='a-strong-password'
./scripts/deploy.sh                      # provisions everything, builds & pushes images
```

`deploy.sh` runs in three phases: (1) create ECR + VPC, (2) build and push the
two images, (3) apply the rest (RDS, ALB, ECS services). It prints the ALB URL
at the end.

```bash
curl http://<alb-dns-name>/            # HTML
curl http://<alb-dns-name>/api/hello   # {"message":"Hello, World!","env":"dev"}
```

Tear everything down:

```bash
./scripts/destroy.sh
```

## Verified on real Fargate

This stack was deployed end-to-end on AWS (2 Fargate tasks + ALB + RDS + NAT) and
served live traffic through the ALB. Quota observations from that run — including
the *Fargate On-Demand vCPU* limit and an Elastic-IP gotcha — are written up in
[`ecs-showcase/docs/quota-check.md`](ecs-showcase/docs/quota-check.md).

## Sizing & cost notes

* Both services run **256 CPU / 512 MB** Fargate tasks (0.25 vCPU each) — small
  on purpose so the stack fits comfortably inside the default *Fargate On-Demand
  vCPU* service quota.
* The always-on cost drivers in this stack are the ALB, the NAT gateway, and the
  RDS instance. For a throwaway demo, set `single_nat_gateway=false` +
  `assign_public_ip=true` to drop the NAT gateway.

## License

MIT
