# Infrastructure as code

| File | Stage | Origin |
|------|-------|--------|
| stage1-acr.bicep | 1 | Export of ACR (Standard) |
| stage2-aci.bicep | 2 | Export of ACI (1 vCPU / 1.5 GB, port 80) |
| stage3-aca.bicep | 3 | Export of Container App (min 0 / max 4) |
| stage4-all.bicep | 4 | Export of App Service plan, web app, staging slot, autoscale, alert |
| stage4-autoscale-settings.json | 4 | Autoscale 1/3/1, CPU > 70 % / < 30 % |
| stage4-action-group.json | 4 | Action group for CPU > 90 % alert |
| stage5-vm-initial.json | 5 | Initial export — `"vmSize": "Standard_B1s"` |
| stage5-vm-after-resize.json | 5 | After resize — `"vmSize": "Standard_B2s"` |
| stage5-vm-before-move.json | 5 | Before move (identical to after-move; move blocked) |
| stage5-vm-after-move.json | 5 | After move (identical; see ../MOVE-NOTE.md) |
| stage5-encryption.json | 5 | CMK encryption template (Key Vault + DES + disk) |
| stage6-vmss.json | 6 | Export of VMSS |
| stage6-autoscale-settings.json | 6 | Autoscale 1/6/1, CPU > 70 % / < 30 % |
| reference/* | 1–6 | Hand-written parameterized fallbacks |

## Notes
- Stage 5 initial export is Standard_B1s. After-resize export is Standard_B2s.
- Resource group move was blocked by lab permissions (see ../MOVE-NOTE.md).
- Stage 4 diagnostic settings omitted (no Log Analytics workspace permission). Logging categories are enabled.
- Subscription IDs, GUIDs, and emails were replaced with placeholders before commit.
