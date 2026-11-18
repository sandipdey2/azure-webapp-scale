# Choosing a compute service: what this project showed

| Service | Cost when idle / always-on | What you manage | How it scales | Choose it when |
|---|---|---|---|---|
| **ACR** | Fixed daily SKU price | Images, tags, access | n/a | Always: private image source |
| **ACI** | Per-second while running | Almost nothing | Manual | Short jobs, PoC |
| **ACA** | Consumption, can scale to 0 | Container + rules | Automatic (KEDA) | Bursty container workloads |
| **App Service** | Plan billed 24/7 | App settings, slots | Automatic (rules) | Web apps needing slots |
| **VM** | Billed while allocated | Everything (OS, disks, NSG) | Manual resize | Full OS control |
| **VMSS** | Per running instance | Same as VM + image + LB | Automatic horizontal | Stateless fleets needing OS control |

## Lab constraints

- Resource group creation blocked → Stage 5 move documented only.
- Log Analytics workspace creation blocked → diagnostic settings omitted; logging categories still enabled.
- Flexible VMSS + Run Command blocked → Stage 6 live load not possible.
- Session resets deleted resources; exports and screenshots captured immediately.
