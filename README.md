# Azure Web App Scaling Journey

This project guides a mock web application through its scaling journey on Azure — from a lightweight container deployment to an enterprise-ready auto-scaling solution.

## Stages

| Stage | Services | Key Deliverables |
|-------|----------|------------------|
| 1 | ACR | `stage1-acr.bicep`, repository list, screenshot |
| 2 | ACI | `stage2-aci.bicep`, CPU/memory before/after, OOMKilled evidence |
| 3 | ACA | `stage3-aca.bicep`, CPU/memory/replicas, OOM evidence |
| 4 | App Service (S1) + Slot + Autoscale | `stage4-all.bicep`, metrics screenshot (CPU + instances = 3), slots, traffic routing |
| 5 | VM (B1s → B2s) | `stage5-vm-initial.json` (B1s), `stage5-vm-after-resize.json` (B2s), MOVE-NOTE.md |
| 6 | VMSS + Autoscale | `stage6-vmss.json`, autoscale rules, scale-out/in metrics |

## Known deviations

- **Stage 1–3**: Clean parameterized reference templates used (original exports lost in lab reset).
- **Stage 4**: App Service plan created in West US 2 (East US S1 quota was 0). Logging categories enabled on production and staging. Diagnostic settings resource omitted because the lab cannot create a Log Analytics workspace (required as a data sink). Metrics screenshot shows CPU Percentage + Observed Capacity reaching 3.
- **Stage 5**: Initial export (`stage5-vm-initial.json`) is Standard_B1s; after-resize export is Standard_B2s. Resource group move blocked by lab permissions (see MOVE-NOTE.md).
- **Stage 6**: Completed with the provided resource group. Autoscale rules and metrics screenshots captured.
- **Centralized monitoring**: Log Analytics workspace could not be created (permission denied). Logging categories were still enabled on App Service.

## Key files

- `MOVE-NOTE.md` — explains the blocked resource group move
- `REFLECTION.md` — service comparison and lab constraints
- `stage4-all.bicep` — App Service + slot + autoscale + alert (logging enabled)
- `stage5-vm-initial.json` — Standard_B1s
- `stage5-vm-after-resize.json` — Standard_B2s

## Lab notes

All work was performed in the Vocareum-provided resource group (`Regroup_*`). The lab role cannot create additional resource groups or Log Analytics workspaces. Screenshots and exports were captured immediately after each stage because lab sessions reset and delete resources.
