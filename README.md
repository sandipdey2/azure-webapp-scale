# Deploy and Manage Azure Compute Resources

Udacity project: one containerized FastAPI app ("Leak-on-Click + CPU Burn") deployed on six Azure compute services.

## Known deviations (lab limitations)

- **Stage 4**: App Service plan created in West US 2 (East US S1 quota was 0). Logging categories (`detailedErrorLoggingEnabled`, `httpLoggingEnabled`, `requestTracingEnabled`) are enabled on production and staging. Diagnostic settings resource omitted because the lab role cannot create a Log Analytics workspace (required as a data sink). Scale-out evidence is the Metrics chart showing CPU Percentage + Observed Capacity reaching 3.
- **Stage 5**: `stage5-vm-initial.json` contains `Standard_B1s`. `stage5-vm-after-resize.json` contains `Standard_B2s`. Resource group move was blocked by lab permissions (see MOVE-NOTE.md).
- **Stage 6**: VMSS and autoscale (min 1 / max 6, CPU 70/30) were created. Live CPU load could not be generated because Run Command and SSH were blocked on Flexible orchestration mode. Evidence is the ARM export and Scaling configuration.
- **Centralized monitoring**: Log Analytics workspace creation was denied. Logging categories were still enabled on App Service.

## Stages

| Stage | Service | Key result |
|-------|---------|------------|
| 1 | ACR | Image pushed |
| 2 | ACI | OOMKilled (exit 137) |
| 3 | ACA | Scaled 0→4, OOM |
| 4 | App Service S1 | Autoscale 1→3, staging slot 30 % |
| 5 | VM | B1s → B2s, CMK disk |
| 6 | VMSS | Autoscale 1/6/1 |

See [REFLECTION.md](REFLECTION.md) and [MOVE-NOTE.md](MOVE-NOTE.md).
