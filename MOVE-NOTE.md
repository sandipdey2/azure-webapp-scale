# Stage 5: Resource group move

**Attempted move:** `Regroup_1acmbdgntz` → new resource group  
**Date:** 2026-11-17  
**Result:** Blocked

## Why the before/after exports are identical
The lab role does not have permission to create a second resource group  
(`Microsoft.Resources/subscriptions/resourceGroups/write` denied).  
Therefore the VM, OS disk, NIC, NSG, public IP and VNet could not be moved.

- `stage5-vm-before-move.json` and `stage5-vm-after-move.json` are identical because the move never occurred.
- Resource IDs, location, size, and configuration did not change.

## What a successful move would have changed
- Every resource ID would have updated in the `/resourceGroups/<old>/` segment to the new group name.
- Cross-resource references (VM → NIC, NIC → subnet/publicIP/NSG, subnet → NSG) would have been rewritten.
- The exported template would have needed to be deployed with `-g <new-rg>`.
- Location, VM size, NSG rules (22, 8000), disk contents, and the static public IP address would have stayed the same.

## Lab limitation
Vocareum lab accounts cannot create additional resource groups.  
All other Stage 5 requirements were completed in the provided resource group:
- Initial export (`stage5-vm-initial.json`) shows `Standard_B1s`
- After-resize export shows `Standard_B2s`
- Metrics screenshots document CPU and memory before/after resize
- Encryption template and disk mount evidence were captured

## Takeaway
A resource group is only a management and RBAC boundary, not a physical location.  
Moving resources updates their identity (ID path) and any hard-coded references, but does not change where they run.  
In environments that block resource-group creation, the before/after comparison must be documented rather than executed.
