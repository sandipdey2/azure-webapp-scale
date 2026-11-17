# Stage 5: resource group move (blocked by the lab)

**Requirement:** move `myapp-vm` (and its NIC, disk, IP, NSG) to a new resource group and compare the ARM export before and after the move.

**What happened:** the lab role cannot create resource groups. `az group create` failed with
`AuthorizationFailed ... Microsoft.Resources/subscriptions/resourcegroups/write`, so there was no target group to move into, and `az resource move` could not run.

**Result:** `stage5-vm-before-move.json` and `stage5-vm-after-move.json` were both exported from the same group (`Regroup_7fpasjkvcc`) and are identical.

**What a real move changes (expected diff):**
- Every resource ID changes from `/resourceGroups/<old-rg>/...` to `/resourceGroups/<new-rg>/...`, and so do the IDs that reference other resources (NIC → VM, NSG/subnet → NIC, public IP → NIC, OS disk → VM).
- The resource names, location, SKU, VM size, Trusted Launch settings and disk encryption stay the same. A move does not redeploy or restart the VM.
- Tags and RBAC assignments scoped to the old group do not follow the resources.

**Command that would have been used:**
```bash
az group create -n my_rg_moved -l eastus
az resource move --destination-group my_rg_moved --ids $(az resource list -g $RG --query "[?contains(name,'myapp-vm')].id" -o tsv)
```
