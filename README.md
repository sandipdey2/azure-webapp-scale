# Deploy and Manage Azure Compute Resources

Udacity project: one containerized FastAPI app ("Leak-on-Click + CPU Burn", from the course starter `HTMLMemoryCPUBurner`) deployed on six Azure compute services. For each service I load-tested CPU and memory, watched how it scaled or failed, and exported the infrastructure as code.

| Stage | Service | Key result |
|---|---|---|
| 1 | Azure Container Registry `cgacr31204` (East US, Standard) | Image `myapp:1.0` (and `2.0`) built server-side with `az acr build` |
| 2 | Azure Container Instances `myapp-aci` (1 vCPU / 1.5 GB) | Memory leak drove usage to ~1 GB → container killed with **ExitCode 137**, restart count 2 |
| 3 | Azure Container Apps `myapp-aca` (env `myapp-env`) | min 0 / max 4, HTTP scale rule: **scaled to 0**, 0→1 on request, **out to 4** under load; leak → exit code 137, 5 restarts |
| 4 | App Service `myapp-web-24786` on plan `myapp-plan` (S1, West US 2) | Autoscale 1/3/1 → **1→2→3 instances**; staging slot running v2.0 with **30 %** traffic; CPU > 90 % alert with email action group |
| 5 | VM `myapp-vm` (Ubuntu 22.04, Trusted Launch) | App as systemd service on :8000; B1s → B2s resize; 8 GB data disk encrypted with a **customer-managed key**, mounted at `/datadisk` |
| 6 | VM Scale Set `myapp-vmss` + Standard Load Balancer | Gallery image `myapp-img 1.0.0`; LB 80→8000 with `/healthz` probe; autoscale 1/6/1 → **scaled out to 6** |

Reflection on when to use each service: [REFLECTION.md](REFLECTION.md). Resource group move note: [MOVE-NOTE.md](MOVE-NOTE.md).

## Repository layout
```
screenshots/   stageN-<rubric item>.png   (portal / Cloud Shell evidence, subscription IDs and personal info removed)
iac/           templates exported or deployed from my own environment
iac/reference/ hand-written, parameterized templates that reproduce each stage (used as fallbacks after lab resets)
evidence/      Cloud Shell outputs saved as text
REFLECTION.md  MOVE-NOTE.md
```

## Rubric → evidence

### Stage 1: Azure Container Registry
| Rubric item | Evidence |
|---|---|
| Registry created, image pushed | `screenshots/stage1-acr-repositories.png` (repo `myapp`, tag `1.0`), `screenshots/stage1-acr-repository-list-cli.png` |
| Bicep template for the registry | `screenshots/stage1-acr-export-bicep.png` (portal export + `az bicep build` → "Bicep compiles OK"); exported file lost in the lab reset (the screenshot stands in); reference `iac/reference/stage1-acr.bicep` |

### Stage 2: Azure Container Instances
| Rubric item | Evidence |
|---|---|
| ACI deployed from ACR (1 vCPU / 1.5 GB, port 80) | `screenshots/stage2-aci-create.png` (Running, 1.0 core / 1.5 GB, `http://myapp-aci-15660.eastus.azurecontainer.io`) |
| CPU / memory before stress | `screenshots/stage2-aci-cpu-before.png`, `screenshots/stage2-aci-memory-before.png` (~35 MB idle) |
| Stress test | `screenshots/stage2-aci-stress-leak-loop.png` (`/cpu/add` + 8 × `/leak`, calls 3 and 6 return `000` while the container restarts) |
| CPU / memory after stress | `screenshots/stage2-aci-cpu-memory-after-oom.png` (CPU spike ~430 millicores, memory ~1 GB, "terminated with ExitCode 137", restarts 2) |
| Out-of-memory kill / restart | `screenshots/stage2-aci-oomkilled-restarts.png` (Previous state *Terminated*, restart count 2) |
| Bicep template | `screenshots/stage2-aci-export-bicep.png` (export → decompile → compiles OK); exported file lost in the lab reset (the screenshot stands in); reference `iac/reference/stage2-aci.bicep` |

### Stage 3: Azure Container Apps
| Rubric item | Evidence |
|---|---|
| Scale rule, min 0 / max 4 | `screenshots/stage3-aca-scale-rules-min0-max4.png` (Min-max replicas 0-4, 1 scale rule, 2/4 replicas active) |
| Scale to zero and 0→1 | `screenshots/stage3-aca-scaled-to-zero.png`, `screenshots/stage3-aca-zero-replicas-cli.png`, `screenshots/stage3-aca-scale-0-to-1.png` |
| Scale out under load | `screenshots/stage3-aca-replica-count.png` (Replica Count 0→1→4), `screenshots/stage3-aca-memory-4-replicas.png` (Memory % chart + 4 replicas listed) |
| Memory limit / OOM | `screenshots/stage3-aca-oom-exit137.png` (log stream + system events "terminated with exit code '137'", restarts 5) |
| Bicep template | `screenshots/stage3-aca-export-bicep.png` (export → decompile → compiles OK); exported file lost in the lab reset (the screenshot stands in); reference `iac/reference/stage3-aca.bicep` |

### Stage 4: App Service
| Rubric item | Evidence |
|---|---|
| Standard S1 plan, scale-out settings | `screenshots/stage4-plan-s1-scale-out.png` |
| Autoscale 1/3/1 on CPU, scaled to 3 | `screenshots/stage4-cpu-scaleout-3.png` (instance count 1 → 2 → 3 during the load test) |
| Deployment slot (staging) | `screenshots/stage4-deployment-slots.png`, `screenshots/stage4-staging-slot-v2.png` (staging serves v2.0) |
| Traffic routing 70 / 30 | `screenshots/stage4-deployment-slots.png` (Traffic % 70 / 30), `screenshots/stage4-traffic-routing.png` (`staging 30.0`) |
| CPU > 90 % alert + email | Metric alert `cpu-over-90` (avg CpuPercentage > 90 over 10 min) → action group `cpu-alert-ag` (email): defined in `iac/stage4-all.bicep` and `iac/stage4-action-group.json`. The alert never fired, because CPU never stayed above 90 % for 10 minutes; the evidence is the action group's **Test** email plus the alert rule page: `screenshots/stage4-alert-email.png`* |
| IaC | `screenshots/stage4-iac-files.png` (files in Cloud Shell); `iac/stage4-all.bicep` (plan, web app, staging slot, metric alert, action group, autoscale; exported from the rebuilt Stage 4 app `myapp-web-15785` after the lab reset), `iac/stage4-autoscale-settings.json` (1/3/1, >70 / <30), `iac/stage4-action-group.json`; reference `iac/reference/stage4-appservice.bicep` |

### Stage 5: Virtual Machine
| Rubric item | Evidence |
|---|---|
| Ubuntu 22.04 Trusted Launch VM running the app on 8000 | `screenshots/stage5-vm-app-port-8000.png` (`http://52.188.158.50:8000`), `evidence/uvicorn-app.service` |
| CPU / memory before and after resize (B1s → B2s) | `screenshots/stage5-vm-memory-before-after.png` (Available Memory jumps after the resize); `screenshots/stage5-vm-cpu-before-after.png`* |
| ARM exports (initial / before move / after move) | `iac/stage5-vm-initial.json`, `iac/stage5-vm-before-move.json`, `iac/stage5-vm-after-move.json` (identical: the move was blocked, and the initial export was taken after the B2s resize); reference `iac/reference/stage5-vm.json`; move explained in `MOVE-NOTE.md` |
| Data disk with customer-managed key | `iac/stage5-encryption.json`, `evidence/stage5-disk-encryption.txt`, `screenshots/stage5-disk-cmk-attached.png` (8 GB, `EncryptionAtRestWithCustomerKey`) |
| Disk mounted | `evidence/stage5-disk-mounted.txt` (`sdc1 8G /datadisk`, test file written) |

### Stage 6: VM Scale Set
| Rubric item | Evidence |
|---|---|
| Gallery image from the VM | `evidence/stage6-image-lb-scale.txt` (image version `Succeeded`) |
| Load balancer 80 → 8000 + health probe | `evidence/stage6-image-lb-scale.txt` (`LBRule 80 → 8000`, `/healthz` → `ok`), `screenshots/stage6-lb-app.png` (`http://20.106.151.220`) |
| Autoscale 1/6/1, CPU > 70 % +1, < 30 % −1 | `screenshots/stage6-autoscale-rules.png`, `screenshots/stage6-autoscale-rules-cli.png` |
| Scale-out under load | `screenshots/stage6-scaleout-capacity-4.png` (1→4), `screenshots/stage6-metrics-scaleout.png` (Observed Capacity 6), `screenshots/stage6-instances.png` (instances 0-4 Running) |
| Scale-in after load | `screenshots/stage6-metrics-scalein.png`* |
| ARM export | `iac/stage6-vmss.json` (VMSS + LB + instances), `iac/stage6-autoscale-settings.json` (1/6/1, >70 / <30); reference `iac/reference/stage6-vmss.json` |

\* = screenshot still being added from the portal (see `SUBMISSION-CHECKLIST.md`).

**Stage 1-3 Bicep exports:** they were generated and compiled in Cloud Shell (see the `stageN-*-export-bicep.png` screenshots: `az group export` → `az bicep decompile` → "Bicep compiles OK"), but the files were lost when the lab reset wiped the first environment. The export screenshots and the matching parameterized templates in `iac/reference/` stand in for them.

## Architecture per stage
1. **ACR**: `az acr build` builds the Dockerfile in Azure (no local Docker), pushes `myapp:1.0`; admin user enabled so ACI/ACA can pull.
2. **ACI**: one Linux container group, public IP + DNS label, port 80, pulls from ACR with registry credentials, restart policy `Always`.
3. **ACA**: Container Apps environment `myapp-env` + app `myapp-aca`, external ingress on 80, revision scale min 0 / max 4 with an HTTP concurrency rule.
4. **App Service**: Linux S1 plan `myapp-plan` (West US 2) → web app `myapp-web-24786` (container `myapp:1.0`) + `staging` slot (`myapp:2.0`), 30 % traffic routed to staging; Azure Monitor autoscale on the plan; metric alert CPU > 90 % → action group email.
5. **VM**: VNet + NSG (22, 8000) + public IP + Trusted Launch Ubuntu 22.04 VM (secure boot + vTPM). App runs as `uvicorn-app` systemd unit. Key Vault (purge protection) → RSA key → disk encryption set (system identity, access policy) → 8 GB managed data disk with SSE + CMK.
6. **VMSS**: VM captured to Azure Compute Gallery `myappgallery` / `myapp-img` 1.0.0 (Specialized, Gen2, Trusted Launch) → Uniform VMSS `myapp-vmss` (B1s) behind a Standard public LB (rule 80 → 8000, HTTP probe `/healthz` on 8000) → autoscale setting `myapp-vmss-autoscale` 1/6/1.

## Key commands (abridged, representative flags)
```bash
# Stage 1
az acr create -g $RG -n cgacr31204 -l eastus --sku Standard --admin-enabled true
az acr build -r cgacr31204 -t myapp:1.0 .
# Stage 2
az container create -g $RG -n myapp-aci --image cgacr31204.azurecr.io/myapp:1.0 --cpu 1 --memory 1.5 --ports 80 \
  --ip-address Public --dns-name-label myapp-aci-15660 --registry-login-server cgacr31204.azurecr.io --registry-username ... --registry-password ...
for i in $(seq 1 8); do curl -s -o /dev/null -w "leak $i -> %{http_code}\n" -X POST $ACI_URL/leak; sleep 30; done
# Stage 3
az containerapp create -g $RG -n myapp-aca --environment myapp-env --image ... --ingress external --target-port 80 \
  --min-replicas 0 --max-replicas 4 --scale-rule-name http-rule --scale-rule-type http --scale-rule-http-concurrency 10
# Stage 4
az appservice plan create -g $RG -n myapp-plan -l westus2 --sku S1 --is-linux
az webapp deployment slot create -g $RG -n $APP --slot staging
az webapp traffic-routing set -g $RG -n $APP --distribution staging=30
az monitor autoscale create -g $RG --resource $PLAN_ID -n $PLAN-autoscale --min-count 1 --max-count 3 --count 1
az monitor metrics alert create -g $RG -n cpu-over-90 --scopes $PLAN_ID --condition "avg CpuPercentage > 90" --action cpu-alert-ag
# Stage 5
az vm create -g $RG -n myapp-vm --image Ubuntu2204 --size Standard_B1s --security-type TrustedLaunch --enable-secure-boot true --enable-vtpm true
az vm resize -g $RG -n myapp-vm --size Standard_B2s
az deployment group create -g $RG -f iac/stage5-encryption.json -p keyVaultName=$KV
az vm disk attach -g $RG --vm-name myapp-vm --name myapp-datadisk
# Stage 6
az sig image-version create -g $RG -r myappgallery -i myapp-img -e 1.0.0 --virtual-machine $VM_ID
az vmss create -g $RG -n myapp-vmss --image $IMG_ID --specialized --vm-sku Standard_B1s --lb myapp-vmss-lb --lb-sku Standard ...
az network lb rule update -g $RG --lb-name myapp-vmss-lb -n LBRule --backend-port 8000 --probe-name http-probe-8000
az monitor autoscale create -g $RG --resource $VMSS_ID -n myapp-vmss-autoscale --min-count 1 --max-count 6 --count 1
az monitor autoscale rule create ... --condition "Percentage CPU > 70 avg 5m" --scale out 1
az monitor autoscale rule create ... --condition "Percentage CPU < 30 avg 7m" --scale in 1
```

## Lab limitations and workarounds
| Limitation | Workaround |
|---|---|
| Lab role cannot create resource groups (`AuthorizationFailed` on `Microsoft.Resources/subscriptions/resourcegroups/write`) | Used the provided `Regroup_*` group with every resource in East US. The Stage 5 resource group move could not be performed; see `MOVE-NOTE.md` (before/after exports are identical). |
| App Service quota for S1 in East US is 0 | Stage 4 plan created in **West US 2**. |
| The lab session reset mid-project (resources wiped) | Stages 1-3 ran in `Regroup_2xspzsnqpi`; their exported Bicep files were lost with that environment (export screenshots kept). After the reset, Stages 4-6 were rebuilt in `Regroup_7fpasjkvcc` with a new registry (`cgacr13672`) and app (`myapp-web-15785`). Most Stage 4 screenshots come from the first Stage 4 run (`myapp-web-24786`); `iac/stage4-*.bicep/json` come from the rebuild. |
| `az group export` omits autoscale settings and action groups (and the CPU alert never fired) | Captured them with `az monitor autoscale show` and `az monitor action-group show` (`stage4-autoscale-settings.json`, `stage4-action-group.json`, `stage6-autoscale-settings.json`). |
| Cloud Shell Microsoft Graph / portal token timeouts broke `az keyvault create` and role assignments | Deployed Key Vault + key + disk encryption set + access policy + encrypted disk in one ARM template (`iac/stage5-encryption.json`), which needs no Graph call. Re-signed in with `az login --use-device-code` when tokens expired. |
| `az vmss create --lb` adds a default rule `LBRule` on 80→80 that clashes with a new 80→8000 rule | Updated `LBRule` to backend port 8000 with probe `http-probe-8000` instead of adding a second rule. |
| No Docker daemon in Cloud Shell | `az acr build` (server-side build). |

## Cleanup
All resources were in the lab resource group. After downloading the evidence:
```bash
az group delete -n Regroup_7fpasjkvcc --yes --no-wait
```
(If the lab blocks group deletion, delete the VMSS, VM, disks, Key Vault, App Service plan and container resources individually.)

## Security note
Subscription, tenant and object IDs, account email addresses, SSH public keys, registry passwords and keys are not included in this repository (exports use `<subscription-id>`, `<guid>`, `<email>`, `<ssh-public-key>` placeholders). Screenshots were cropped or masked to remove the browser address bar (which contained the subscription ID) and the bookmarks bar.
