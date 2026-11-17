# Items still to add before final review

Everything else in the rubric table of `README.md` is already in this repo. The files below exist only in my Azure Cloud Shell home directory or in the portal, so they are added separately.

## 1. Exported IaC files (Cloud Shell → `iac/`)
Run this in Cloud Shell. It copies each export, replaces the subscription ID, any GUIDs and email addresses with placeholders, and zips the result:
```bash
cd ~ && rm -rf iac-clean && mkdir iac-clean
SUB=$(az account show --query id -o tsv)
for f in stage1-acr.bicep stage2-aci.bicep stage3-aca.bicep stage4-all.bicep stage4-autoscale-settings.json stage4-action-group.json \
         stage5-vm-initial.json stage5-vm-before-move.json stage5-vm-after-move.json stage6-vmss.json stage6-autoscale-settings.json; do
  if [ -f "$f" ]; then
    sed -E "s/$SUB/<subscription-id>/g; s/[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}/<guid>/g; s/[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}/<email>/g" "$f" > iac-clean/$f && echo "OK $f"
  else echo "MISSING $f"; fi
done
zip -r iac-clean.zip iac-clean && ls -la iac-clean
```
Download `iac-clean.zip` (Manage files → Download) and put the files in `iac/`.

## 2. Screenshots (portal → `screenshots/`)
| File | Where to capture |
|---|---|
| `stage3-aca-cpu.png` | Container App `myapp-aca` → Monitoring → Metrics → *CPU Usage* + *Replica Count*, last 24 h (only if the lab still has Stage 3; otherwise the replica-count and memory screenshots cover scaling) |
| `stage4-alert-email.png` | The "Fired: cpu-over-90" email from Azure Monitor in the inbox used by the action group (mask the email address) |
| `stage5-vm-cpu-before-after.png` | `myapp-vm` → Monitoring → Metrics → *Percentage CPU*, last 24 h (covers the B1s and B2s runs) |
| `stage6-metrics-scalein.png` | `myapp-vmss` → Availability + scale → Scaling → *Run history* (Observed capacity going back down after the load stopped), or Metrics → *Percentage CPU* + *Observed Capacity* |

Crop the browser address bar (it contains the subscription ID) before adding a screenshot.

When everything is in place, delete this file.
