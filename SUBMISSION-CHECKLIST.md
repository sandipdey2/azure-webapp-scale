# Items still to add before final review

All IaC files are in `iac/`. The Stage 1-3 exported Bicep files were lost in the lab reset; their export screenshots stand in for them (see `iac/README.md`). Only these screenshots remain:

| File | Where to capture |
|---|---|
| `stage4-alert-email.png` | The CPU > 90 % alert never fired (CPU never stayed above 90 % for 10 minutes). Capture instead: Monitor → Alerts → Action groups → `cpu-alert-ag` → **Test action group** → email, then the email received from Azure Monitor (mask the address), plus Monitor → Alerts → Alert rules → `cpu-over-90` showing the condition and the action group |
| `stage5-vm-cpu-before-after.png` | `myapp-vm` → Monitoring → Metrics → *Percentage CPU*, last 24 h (covers the B1s and B2s runs) |
| `stage6-metrics-scalein.png` | `myapp-vmss` → Availability + scale → Scaling → *Run history* (Observed capacity going back down after the load stopped), or Metrics → *Percentage CPU* + *Observed Capacity* |

Crop the browser address bar (it contains the subscription ID) before adding a screenshot. When all three are in, delete this file.
