table 888 "SmartList Designer Setup"
{
    Access = Internal;
    DataPerCompany = false;
    Extensible = false;
    DataClassification = OrganizationIdentifiableInformation;
#if not CLEAN19
    ObsoleteState = Pending;
    ObsoleteTag = '19.0';
#else
    ObsoleteState = Removed;
    ObsoleteTag = '22.0';
#endif
    ObsoleteReason = 'The SmartList Designer is not supported in Business Central.';

    fields
    {
        field(1; PrimaryKey; Code[10])
        {
            Caption = 'Primary Key';
            DataClassification = SystemMetadata;
        }

        field(2; PowerAppId; Guid)
        {
            Caption = 'Power App Id';
            DataClassification = SystemMetadata;
            trigger OnValidate()
            begin
                TestField(PowerAppId);
            end;
        }

        field(3; PowerAppTenantId; Guid)
        {
            Caption = 'Power App Tenant Id';
            DataClassification = OrganizationIdentifiableInformation;
            trigger OnValidate()
            begin
                TestField(PowerAppTenantId);
            end;
        }
    }

    keys
    {
        key(PK; PrimaryKey)
        {
            Clustered = true;
        }
    }
}