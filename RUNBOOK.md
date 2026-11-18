# Deploy and Manage Azure Compute Resources: Runbook

Six stages, run in order in **Azure Cloud Shell (Bash)**. Every rubric deliverable is a step marked **📸 / 📄**.

> **Lab sessions reset without warning and wipe resources.** Capture each deliverable as soon as its step finishes.

## Known lab limitations (Vocareum)

| Limit | Impact | Workaround used |
|-------|--------|-----------------|
| Cannot create resource groups | Stage 5 move blocked | Documented in MOVE-NOTE.md; all work done in provided `Regroup_*` group |
| Cannot create Log Analytics workspace | Diagnostic settings require a sink | Logging categories enabled on App Service; diagnosticSettings resource omitted |
| App Service S1 quota = 0 in East US | Plan cannot be created in eastus | Created in West US 2 |
| Session resets delete resources | Exports and screenshots can be lost | Recreated B1s VM and re-exported when needed |

## Stage 4 notes (updated)
- Logging enabled: `detailedErrorLoggingEnabled`, `httpLoggingEnabled`, `requestTracingEnabled` = true on production and staging.
- Metrics screenshot shows CPU Percentage + Observed Capacity reaching 3.
- Diagnostic settings resource could not be deployed (no workspace sink available).

## Stage 5 notes (updated)
- `stage5-vm-initial.json` contains `"vmSize": "Standard_B1s"`.
- `stage5-vm-after-resize.json` contains `"vmSize": "Standard_B2s"`.
- Resource group move blocked — see MOVE-NOTE.md.

## Final deliverables checklist
```
stage1-acr.bicep
stage2-aci.bicep
stage3-aca.bicep
stage4-all.bicep (or stage4-appservice.bicep)
stage4-metrics-cpu-instances.png
stage5-vm-initial.json          ← Standard_B1s
stage5-vm-after-resize.json     ← Standard_B2s
MOVE-NOTE.md
REFLECTION.md
stage6-vmss.json
... (remaining screenshots)
```

All other original runbook steps remain valid. Use the provided `Regroup_*` resource group for every deployment.
