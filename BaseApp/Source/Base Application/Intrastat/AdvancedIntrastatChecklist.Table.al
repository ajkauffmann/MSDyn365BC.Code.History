table 8452 "Advanced Intrastat Checklist"
{
    Caption = 'Advanced Intrastat Checklist';

    fields
    {
        field(1; "Object Type"; Option)
        {
            Caption = 'Object Type';
            OptionMembers = ,,,Report,,Codeunit;
        }
        field(2; "Object Id"; Integer)
        {
            Caption = 'Object Id';
            TableRelation = if ("Object Type" = const(Report)) "Report Metadata".ID else
            if ("Object Type" = const(Codeunit)) "CodeUnit Metadata".ID;
        }
        field(3; "Object Name"; Text[250])
        {
            Caption = 'Object Name';
            FieldClass = FlowField;
            Editable = false;
            CalcFormula = Lookup(AllObjWithCaption."Object Caption" where("Object Type" = field("Object Type"), "Object ID" = field("Object Id")));
        }
        field(4; "Field No."; Integer)
        {
            Caption = 'Field No.';
            NotBlank = true;
            TableRelation = Field."No." where(TableNo = const(263), "No." = filter(<> 1 & <> 2 & <> 3 & < 2000000000), Class = const(Normal), ObsoleteState = const(No));
        }
        field(5; "Field Name"; Text[250])
        {
            Caption = 'Field Name';
            FieldClass = FlowField;
            Editable = false;
            CalcFormula = Lookup(Field."Field Caption" where(TableNo = const(263), "No." = field("Field No.")));
        }
        field(6; "Filter Expression"; Text[1024])
        {
            Caption = 'Filter Expression';
            trigger OnValidate()
            var
                IntrastatJnlLine: Record "Intrastat Jnl. Line";
            begin
                if "Filter Expression" <> '' then begin
                    IntrastatJnlLine.SetView(ConvertFilterStringToView("Filter Expression"));
                    "Record View String" := CopyStr(IntrastatJnlLine.GetView(false), 1, MaxStrLen("Record View String"));
                    "Filter Expression" := CopyStr(IntrastatJnlLine.GetFilters(), 1, MaxStrLen("Filter Expression"));
                end else
                    "Record View String" := '';
            end;

            trigger OnLookup()
            begin
                LookupFilterExpression();
            end;
        }
        field(7; "Record View String"; Text[1024])
        {
            Caption = 'Record View String';
            DataClassification = SystemMetadata;
            Editable = false;
        }
    }

    keys
    {
        key(Key1; "Object Type", "Object Id", "Field No.")
        {
            Clustered = true;
        }
    }

    var
        FilterStringParseErr: Label 'Could not parse the filter expression. Use the lookup action, or type a string in the following format: "Type: Shipment, Quantity: <>0".';
        FilterTxt: Label '%1=FILTER(%2)', Locked = true;
        WhereTxt: Label '%1 WHERE(%2)', Locked = true;

    procedure AssistEditFieldName()
    var
        Field: Record Field;
        FieldSelection: Codeunit "Field Selection";
    begin
        Field.SetRange(TableNo, Database::"Intrastat Jnl. Line");
        Field.SetRange(IsPartOfPrimaryKey, false);
        Field.SetFilter("No.", '<%1', Field.FieldNo(SystemId));
        Field.SetRange(Class, Field.Class::Normal);
        Field.SetRange(ObsoleteState, Field.ObsoleteState::No);
        if FieldSelection.Open(Field) then
            Validate("Field No.", Field."No.");
    end;

    local procedure LookupFilterExpression()
    var
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
        FilterPageBuilder: FilterPageBuilder;
        TableCaptionValue: Text;
    begin
        TableCaptionValue := IntrastatJnlLine.TableCaption();
        FilterPageBuilder.AddTable(TableCaptionValue, Database::"Intrastat Jnl. Line");
        if "Record View String" <> '' then
            FilterPageBuilder.SetView(TableCaptionValue, "Record View String");
        if FilterPageBuilder.RunModal() then begin
            IntrastatJnlLine.SetView(FilterPageBuilder.GetView(TableCaptionValue, false));
            "Record View String" := CopyStr(IntrastatJnlLine.GetView(false), 1, MaxStrLen("Record View String"));
            "Filter Expression" := CopyStr(IntrastatJnlLine.GetFilters(), 1, MaxStrLen("Filter Expression"));
        end;
    end;

    local procedure ConvertFilterStringToView(FilterString: Text): Text
    var
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
        ConvertedFilterString: Text;
        MidPos: Integer;
        FinishPos: Integer;
    begin
        WHILE FilterString <> '' DO begin
            // Convert "Type: Receipt" to "Type=FILTER(Receipt)"
            MidPos := StrPos(FilterString, ':');
            if MidPos < 2 then
                Error(FilterStringParseErr);
            FinishPos := StrPos(FilterString, ',');
            if FinishPos = 0 then
                FinishPos := StrLen(FilterString) + 1;
            if ConvertedFilterString <> '' then
                ConvertedFilterString += ',';
            ConvertedFilterString +=
              StrSubstNo(FilterTxt, CopyStr(FilterString, 1, MidPos - 1), CopyStr(FilterString, MidPos + 1, FinishPos - MidPos - 1));
            FilterString := DelStr(FilterString, 1, FinishPos);
        end;

        if ConvertedFilterString <> '' then
            exit(StrSubstNo(WhereTxt, IntrastatJnlLine.GetView(), ConvertedFilterString));

        exit('');
    end;

    procedure LinePassesFilterExpression(IntrastatJnlLine: Record "Intrastat Jnl. Line"): Boolean
    var
        TempIntrastatJnlLine: Record "Intrastat Jnl. Line" temporary;
    begin
        if "Record View String" = '' then
            exit(true);

        TempIntrastatJnlLine := IntrastatJnlLine;
        TempIntrastatJnlLine.Insert();
        TempIntrastatJnlLine.SetView("Record View String");
        exit(not TempIntrastatJnlLine.IsEmpty());
    end;
}

