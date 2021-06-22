PermissionSet 9016 "Azure AD Plan - Read"
{
    Access = Internal;
    Assignable = false;

    IncludedPermissionSets = "User Login Times - Read",
                             "Azure AD User - View",
                             "Upgrade Tags - Read";

    Permissions = tabledata Company = r,
                  tabledata Plan = r,
                  tabledata User = r,
                  tabledata "User Plan" = r;
}
