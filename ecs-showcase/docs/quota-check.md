# ECS Fargate deploy — quota check

Result of a real end-to-end deploy of this stack (account `372806410594`,
`us-east-1`, 2 × `256 CPU / 512 MB` Fargate tasks + ALB + RDS + NAT gateway).

## Verdict

The deploy **succeeded with no quota blocks on Fargate.** Both tasks reached
steady state, the ALB target was healthy, and the app served traffic
(`/`, `/api/hello`, and a DB-backed `POST /api/messages`).

## Quotas that matter for this stack

| Quota | Code | Limit | This deploy used | Headroom |
| ----- | ---- | ----- | ---------------- | -------- |
| **Fargate On-Demand vCPU** | `L-3032A538` | **6 vCPU** | 0.5 vCPU (2 × 0.25) | ~24 tasks of this size |
| Elastic IPs | `L-0263D0A3` | 5 | +1 (NAT gateway) | ⚠️ account was at **5/5** after deploy |
| VPCs per region | `L-F678F1CE` | 5 | +1 | fine |
| Fargate On-Demand burst launch rate | `L-6BAD92DD` | 100/s | trivial | fine |

## Takeaways

1. **Fargate vCPU is the quota to watch, and it's fine here.** The default
   *Fargate On-Demand vCPU resource count* is **6 vCPU** on this account. At the
   showcase's `0.25 vCPU` per task that's headroom for ~24 tasks — but it is
   easy to blow through if you bump task sizes (a single `1 vCPU / 2 GB` task
   with `desired_count = 6` already hits the ceiling) or fan out replicas. It's
   an **adjustable** quota — request an increase in Service Quotas before scaling
   up. Brand-new accounts sometimes start lower, so check before a big rollout.

2. **Elastic IPs were the real pinch point.** The single NAT gateway takes one
   EIP and the account ended at **5/5 EIPs (the default hard-ish limit).** This
   is why the stack defaults to `single_nat_gateway = true`. Flipping to one NAT
   per AZ (`single_nat_gateway = false`) would need 2 EIPs and **fail** here
   without an EIP quota increase. The NAT-free option
   (`assign_public_ip = true`, no NAT gateway) sidesteps EIPs entirely.

3. No ECS-service-count, task-def, or launch-rate limits were anywhere near
   being hit for a workload this size.

_Generated from a live `terraform apply` run; re-run `aws service-quotas
get-service-quota --service-code fargate --quota-code L-3032A538` to see the
current Fargate vCPU limit._
