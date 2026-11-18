# Choosing a compute service: what this project showed

| Service | Cost when idle / always-on | What you manage | How it scales | Choose it when |
|---|---|---|---|---|
| **ACR** | Fixed daily SKU price (Standard), plus storage | Images, tags, access | n/a (registry) | Always: one private source of images for every service below |
| **ACI** | Per-second vCPU + GiB while the group exists. Cheap for short jobs, pricey 24/7 | Almost nothing. No OS, but no autoscale or LB either | **Manual**: one fixed-size group. You redeploy to resize, and OOM simply restarts it | Quick PoC, batch or cron jobs, a sidecar task, CI agents |
| **ACA** | Consumption: per-second, **can scale to 0**, free monthly grant. Cheapest for spiky or idle apps | Container + scale rules. Platform handles OS, ingress, TLS, revisions | **Automatic**: KEDA rules (CPU, HTTP, queue), 0→N replicas in seconds | Microservices, APIs and event-driven workloads with bursty traffic |
| **App Service** | Plan billed 24/7 per instance (S1+ for slots/autoscale), even when idle | App settings, slots, plan size. Platform patches OS and runtime | **Automatic** rule-based (Azure Monitor autoscale), 1→N instances in minutes. Slots give A/B and zero-downtime swaps | Classic web apps or APIs that need slots, custom domains and easy CI/CD |
| **VM** | Billed while allocated (deallocate to stop compute cost), plus disks and IP | **Everything**: OS patching, runtime, systemd, NSG, disks, CMK encryption, backups | **Manual**: resize = reboot (vertical only) | Full control: custom OS/agents, legacy software, special disk or compliance needs (CMK) |
| **VMSS** | Per running instance. Min 1 keeps a floor cost | Same as VM, but via a golden image (gallery) + LB + health probe | **Automatic** horizontal scaling (here 1–6 on CPU 70/30), with minutes of lag per instance | Stateless IaaS fleets that need OS control **and** elasticity |

**Lessons from the lab**
- **Granularity versus control.** ACA scaled in seconds and could reach zero. App Service and VMSS took minutes per step and add cooldowns (5 and 7 min), so they need headroom for sudden spikes.
- **Resource limits fail differently.** ACI and ACA kill the container on the memory limit (OOMKilled / exit 137) and restart it. The VM just ran out of headroom until I resized it. Autoscale on CPU doesn't fix a memory leak, because every new instance leaks too.
- **Operational load grows to the right of the table.** The VM path needed cloud-init, a systemd unit, NSG rules, Key Vault + DES for CMK, and image capture. ACA needed one command.
- **What I'd pick:** ACA for a new containerized web app; App Service when the team wants slots and a familiar PaaS; VMSS only when OS-level control is a hard requirement; ACI for one-off jobs.

## Lab constraints that affected implementation

- Resource group creation is blocked → Stage 5 move could not be executed; documented in MOVE-NOTE.md instead.
- Log Analytics workspace creation is blocked (`Microsoft.OperationalInsights/workspaces/write` denied). Diagnostic settings therefore could not be created with a workspace sink. Logging categories were still enabled on the App Service (`detailedErrorLoggingEnabled`, `httpLoggingEnabled`, `requestTracingEnabled` = true).
- App Service S1 quota was 0 in East US → plan was created in West US 2.
- Lab sessions reset and delete resources → screenshots and exports were captured as soon as each stage completed. The initial VM export (`stage5-vm-initial.json`) was recreated as Standard_B1s after a reset.
