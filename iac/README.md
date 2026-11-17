# Infrastructure as code

| File | Stage | Origin |
|---|---|---|
| `stage5-encryption.json` | 5 | The ARM template I deployed (`az deployment group create -n stage5-cmk`) to create Key Vault, RSA key, disk encryption set, access policy and the 8 GB CMK-encrypted data disk |
| `stage1-acr.bicep`, `stage2-aci.bicep`, `stage3-aca.bicep`, `stage4-all.bicep`, `stage4-autoscale-settings.json`, `stage4-action-group.json`, `stage5-vm-initial.json`, `stage5-vm-before-move.json`, `stage5-vm-after-move.json`, `stage6-vmss.json`, `stage6-autoscale-settings.json` | 1-6 | Exported from my deployment with `az group export` (+ `az bicep decompile`) or `az monitor ... show`; IDs replaced with placeholders |
| `reference/*.bicep`, `reference/*.json` | 1-6 | Hand-written, parameterized templates that redeploy each stage (`az deployment group create -g <rg> -f <file> -p ...`). Used as fallbacks after the lab reset. They contain no subscription IDs or secrets; passwords are `@secure()` parameters. |
