# NOT OFFICIALLY SUPPORTED BY PURE
#
# Create-ActiveClusterWithCBS.ps1
#
# : Revision 1.0.0.0
# :: initial release
#
# Example script to create an ActiveCluster configuration between a on-premises FlashArray and a Pure Cloud Block Store array.
# This is not intended to be a complete run script. It is for example purposes only.
# Variables should be modified to suit the environment.
#
# This script is AS-IS. No warranties expressed or implied by Pure Storage or the author.
#
# Requirements:
#
#
#### Start
# create POD
New-PfaPod -Array $Array -Name "azsqlfci"

