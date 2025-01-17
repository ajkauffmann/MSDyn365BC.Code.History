codeunit 104070 "Upgrade Refs To Rem. Tables"
{
    Subtype = Upgrade;

    trigger OnUpgradePerCompany()
    var
        RemovedTablesFilter: Text;
    begin
        // There is no check for upgrade tags, as this code needs to run
        // on every upgrade (in case more tables got removed)

        RemovedTablesFilter := GetRemovedTablesFilter();
        CleanUpChangeLogSetup(RemovedTablesFilter);
    end;

    local procedure CleanUpChangeLogSetup(RemovedTablesFilter: Text)
    var
        ChangeLogSetupTable: Record "Change Log Setup (Table)";
    begin
        ChangeLogSetupTable.SetFilter("Table No.", RemovedTablesFilter);
        ChangeLogSetupTable.DeleteAll();
    end;

    local procedure GetRemovedTablesFilter(): Text
    var
        TableMetadata: Record "Table Metadata";
        SelectionFilterManagement: Codeunit SelectionFilterManagement;
        TableMetadataRecordRef: RecordRef;
    begin
        TableMetadata.SetRange(ObsoleteState, TableMetadata.ObsoleteState::Removed);
        TableMetadataRecordRef.GetTable(TableMetadata);
        exit(SelectionFilterManagement.GetSelectionFilter(TableMetadataRecordRef, TableMetadata.FieldNo(ID), false));
    end;
}