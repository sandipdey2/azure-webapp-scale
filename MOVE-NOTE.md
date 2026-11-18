# Stage 5: Resource group move (blocked by the lab)

**Attempted move:** provided resource group → new resource group  
**Result:** Blocked

The lab role does not have permission to create a second resource group  
(`Microsoft.Resources/subscriptions/resourceGroups/write` denied).  
Therefore the VM and its related resources could not be moved.

- `stage5-vm-before-move.json` and `stage5-vm-after-move.json` are identical because the move never occurred.
- Resource IDs, location, size, and configuration did not change.

**Initial export:** `stage5-vm-initial.json` contains `"vmSize": "Standard_B1s"`.  
**After resize:** `stage5-vm-after-resize.json` contains `"vmSize": "Standard_B2s"`.

A resource group is only a management and RBAC boundary. Moving resources updates their IDs but does not change where they run.
