# Deploy and Manage Azure Compute Resources

Udacity project: one containerized FastAPI app ("Leak-on-Click + CPU Burn") deployed on six Azure compute services.

## Known deviations (lab limitations)

- **Stage 4**: App Service plan created in West US 2 (East US S1 quota was 0). Logging categories (`detailedErrorLoggingEnabled`, `httpLoggingEnabled`, `requestTracingEnabled`) are enabled on production and staging. Diagnostic settings resource omitted because the lab role cannot create a Log Analytics workspace (required as a data sink). Scale-out evidence is the Metrics chart showing CPU Percentage + Observed Capacity reaching 3 (`screenshots/stage4-metrics-cpu-instances.png` or the updated `stage4-cpu-scaleout-3.png`).
- **Stage 5**: `stage5-vm-initial.json` contains `Standard_B1s`. `stage5-vm-after-resize.json` contains `Standard_B2s`. Resource group move was blocked by lab permissions (see MOVE-NOTE.md).
- **Stage 6**: VMSS and autoscale (min 1 / max 6, CPU 70/30) were created. Live CPU load could not be generated because Run Command and SSH were blocked on Flexible orchestration mode. Evidence is the ARM export and Scaling configuration.
- **Centralized monitoring**: Log Analytics workspace creation was denied. Logging categories were still enabled on App Service.

## Stages

| Stage | Service | Key result |
|-------|---------|------------|
| 1 | ACR | Image pushed |
| 2 | ACI | OOMKilled (exit 137) |
| 3 | ACA | Scaled 0→4, OOM |
| 4 | App Service S1 | Autoscale 1→3, staging slot 30 %, Metrics screenshot shows capacity = 3 |
| 5 | VM | Initial export = B1s, after-resize = B2s, CMK disk, move blocked |
| 6 | VMSS | Autoscale 1/6/1 (live load blocked by lab) |

See [REFLECTION.md](REFLECTION.md) and [MOVE-NOTE.md](MOVE-NOTE.md).

## Rubric → evidence (key items)

### Stage 4
- Scale-out to 3: Metrics chart with CPU Percentage + Observed Capacity = 3
- Logging enabled on production and staging
- Diagnostic settings omitted (no Log Analytics workspace permission)

### Stage 5
- `iac/stage5-vm-initial.json` → `"vmSize": "Standard_B1s"`
- `iac/stage5-vm-after-resize.json` → `"vmSize": "Standard_B2s"`
- Move blocked — see MOVE-NOTE.md
- Before/after CPU and memory screenshots captured

### Stage 6
- Autoscale rules 1/6/1 with CPU 70/30
- ARM export `iac/stage6-vmss.json`
- Live load blocked by lab permissions
