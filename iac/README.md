# Infrastructure as code

| File | Stage | Origin |
|---|---|---|
| `stage4-all.bicep` | 4 | `az group export` → `az bicep decompile` of the rebuilt Stage 4 environment (`Regroup_7fpasjkvcc`): ACR `cgacr13672`, plan `myapp-plan` (S1, West US 2), web app `myapp-web-15785` + `staging` slot, metric alert `cpu-over-90`, action group `cpu-alert-ag`, autoscale `myapp-plan-autoscale` |
| `stage4-autoscale-settings.json` | 4 | `az monitor autoscale show` (target: App Service plan `myapp-plan`; min/max/default 1/3/1; CPU > 70 → +1, < 30 → −1) |
| `stage4-action-group.json` | 4 | `az monitor action-group show -n cpu-alert-ag` (email receiver; address replaced by `<email>`) |
| `stage5-vm-initial.json`, `stage5-vm-before-move.json`, `stage5-vm-after-move.json` | 5 | `az group export` of `myapp-vm` and its network resources. The three files are identical: the resource group move was blocked by the lab (see `../MOVE-NOTE.md`), and the initial export was taken after the B1s → B2s resize. SSH public key replaced by `<ssh-public-key>` |
| `stage5-encryption.json` | 5 | The ARM template I deployed (`az deployment group create -n stage5-cmk`): Key Vault, RSA key, disk encryption set, access policy and the 8 GB CMK-encrypted data disk |
| `stage6-vmss.json` | 6 | `az group export` of `myapp-vmss` and `myapp-vmss-lb` (VMSS from gallery image `myapp-img` 1.0.0, LB rule 80 → 8000, probe, instances) |
| `stage6-autoscale-settings.json` | 6 | `az monitor autoscale show` (target: `myapp-vmss`; 1/6/1; CPU > 70 → +1, < 30 → −1) |
| `reference/*.bicep`, `reference/*.json` | 1-6 | Hand-written, parameterized templates that redeploy each stage (`az deployment group create -g <rg> -f <file> -p ...`). Used as fallbacks after the lab reset. No subscription IDs or secrets; passwords are `@secure()` parameters |

**Stage 1-3 exports:** `stage1-acr.bicep`, `stage2-aci.bicep` and `stage3-aca.bicep` were exported and compiled in Cloud Shell (screenshots `stage1-acr-export-bicep.png`, `stage2-aci-export-bicep.png`, `stage3-aca-export-bicep.png`), but were lost when the lab reset wiped that environment. The screenshots and `reference/stage1-3` templates stand in for them.

All exports had the subscription ID, other GUIDs and email addresses replaced with `<subscription-id>`, `<guid>` and `<email>` before being committed.
