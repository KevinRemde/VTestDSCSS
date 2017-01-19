# VTestDSCSS
This is a sample that creates a scale set of VMs, as well as creates an Azure Automation account.  It populates the automation with DSC configuration, and then applies the configuration to all VMs in the scale set.

This particular example configures the VMs as web servers, as well as installing a utility.

The Azure Automation DSC is set to auto-correct, so any changes to the VM configuration will be detected and fixed. 