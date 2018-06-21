Connect-F5 -ip 10.219.1.183

New-DefaultAcl -name "Rich" -subnet "10.194.57.192/26"

Add-APMRole -name "aggregate_acl_act_full_resource_assign_ag" -acl "Rich" -group "Rich_awsgroup"

Update-APMPolicy -name "CSN_VPN_Streamlined"