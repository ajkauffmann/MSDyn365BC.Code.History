codeunit 132502 "Purch. Document Posting Errors"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Error Message] [Purchase]
    end;

    var
        Assert: Codeunit Assert;
        LibraryERM: Codeunit "Library - ERM";
        LibraryErrorMessage: Codeunit "Library - Error Message";
        LibraryPurchase: Codeunit "Library - Purchase";
        PostingDateNotAllowedErr: Label 'Posting Date is not within your range of allowed posting dates.';
        LibraryTimeSheet: Codeunit "Library - Time Sheet";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryUtility: Codeunit "Library - Utility";
        IsInitialized: Boolean;
        NothingToPostErr: Label 'There is nothing to post.';
        DefaultDimErr: Label 'Select a Dimension Value Code for the Dimension Code %1 for Vendor %2.';

        // Expected error messages (from code unit 90).
        PurchRcptHeaderConflictErr: Label 'Cannot post the purchase receipt because its ID, %1, is already assigned to a record. Update the number series and try again.', Comment = '%1 = Receiving No.';
        ReturnShptHeaderConflictErr: Label 'Cannot post the return shipment because its ID, %1, is already assigned to a record. Update the number series and try again.', Comment = '%1 = Return Shipment No.';
        PurchInvHeaderConflictErr: Label 'Cannot post the purchase invoice because its ID, %1, is already assigned to a record. Update the number series and try again.', Comment = '%1 = Posting No.';

    [Test]
    [Scope('OnPrem')]
    procedure T001_PostingDateIsInNotAllowedPeriodInGLSetup()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        PurchHeader: Record "Purchase Header";
        TempErrorMessage: Record "Error Message" temporary;
        GeneralLedgerSetupPage: TestPage "General Ledger Setup";
        PurchInvoicePage: TestPage "Purchase Invoice";
    begin
        // [SCENARIO] Posting of document, where "Posting Date" is out of the allowed period, set in G/L Setup
        Initialize;
        // [GIVEN] "Allow Posting To" is 31.12.2018 in "General Ledger Setup"
        LibraryERM.SetAllowPostingFromTo(0D, WorkDate - 1);
        // [GIVEN] Invoice '1001', where "Posting Date" is 01.01.2019
        LibraryPurchase.CreatePurchaseInvoice(PurchHeader);
        PurchHeader.TestField("Posting Date", WorkDate);

        // [WHEN] Post Invoice '1001'
        LibraryErrorMessage.TrapErrorMessages;
        PurchHeader.SendToPosting(CODEUNIT::"Purch.-Post");

        // [THEN] "Error Message" page is open, where is one error:
        // [THEN] "Posting Date is not within your range of allowed posting dates."
        LibraryErrorMessage.GetErrorMessages(TempErrorMessage);
        Assert.RecordCount(TempErrorMessage, 1);
        TempErrorMessage.FindFirst;
        TempErrorMessage.TestField(Description, PostingDateNotAllowedErr);
        // [THEN] "Context" is 'Purchase Header: Invoice, 1001', "Field Name" is 'Posting Date',
        TempErrorMessage.TestField("Context Record ID", PurchHeader.RecordId);
        TempErrorMessage.TestField("Context Table Number", DATABASE::"Purchase Header");
        TempErrorMessage.TestField("Context Field Number", PurchHeader.FieldNo("Posting Date"));
        // [THEN] "Source" is 'G/L Setup', "Field Name" is 'Allow Posting From'
        GeneralLedgerSetup.Get();
        TempErrorMessage.TestField("Record ID", GeneralLedgerSetup.RecordId);
        TempErrorMessage.TestField("Table Number", DATABASE::"General Ledger Setup");
        TempErrorMessage.TestField("Field Number", GeneralLedgerSetup.FieldNo("Allow Posting From"));
        // [WHEN] DrillDown on "Source"
        GeneralLedgerSetupPage.Trap;
        LibraryErrorMessage.DrillDownOnSource;
        // [THEN] opens "General Ledger Setup" page.
        GeneralLedgerSetupPage."Allow Posting To".AssertEquals(WorkDate - 1);
        GeneralLedgerSetupPage.Close;

        // [WHEN] DrillDown on "Description"
        PurchInvoicePage.Trap;
        LibraryErrorMessage.DrillDownOnContext();
        // [THEN] opens "Purchase Invoice" page.
        PurchInvoicePage."Posting Date".AssertEquals(WorkDate);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T002_PostingDateIsInNotAllowedPeriodInUserSetup()
    var
        PurchHeader: Record "Purchase Header";
        TempErrorMessage: Record "Error Message" temporary;
        UserSetup: Record "User Setup";
        UserSetupPage: TestPage "User Setup";
        PurchInvoicePage: TestPage "Purchase Invoice";
    begin
        // [SCENARIO] Posting of document, where "Posting Date" is out of the allowed period, set in User Setup.
        Initialize;
        // [GIVEN] "Allow Posting To" is 31.12.2018 in "User Setup"
        LibraryTimeSheet.CreateUserSetup(UserSetup, true);
        UserSetup."Allow Posting To" := WorkDate - 1;
        UserSetup.Modify();
        // [GIVEN] Invoice '1001', where "Posting Date" is 01.01.2019
        LibraryPurchase.CreatePurchaseInvoice(PurchHeader);
        PurchHeader.TestField("Posting Date", WorkDate);

        // [WHEN] Post Invoice '1001'
        LibraryErrorMessage.TrapErrorMessages;
        PurchHeader.SendToPosting(CODEUNIT::"Purch.-Post");

        // [THEN] "Error Message" page is open, where is one error:
        // [THEN] "Posting Date is not within your range of allowed posting dates."
        LibraryErrorMessage.GetErrorMessages(TempErrorMessage);
        Assert.RecordCount(TempErrorMessage, 1);
        TempErrorMessage.FindFirst;
        TempErrorMessage.TestField(Description, PostingDateNotAllowedErr);
        // [THEN] Call Stack contains '"Purch.-Post"(CodeUnit 90).CheckAndUpdate'
        Assert.ExpectedMessage('"Purch.-Post"(CodeUnit 90).CheckAndUpdate ', TempErrorMessage.GetErrorCallStack());
        // [THEN] "Context" is 'Purchase Header: Invoice, 1001', "Field Name" is 'Posting Date',
        TempErrorMessage.TestField("Context Record ID", PurchHeader.RecordId);
        TempErrorMessage.TestField("Context Field Number", PurchHeader.FieldNo("Posting Date"));
        // [THEN]  "Source" is 'User Setup',  "Field Name" is 'Allow Posting From'
        TempErrorMessage.TestField("Record ID", UserSetup.RecordId);
        TempErrorMessage.TestField("Field Number", UserSetup.FieldNo("Allow Posting From"));
        // [WHEN] DrillDown on "Source"
        UserSetupPage.Trap;
        LibraryErrorMessage.DrillDownOnSource;
        // [THEN] opens "User Setup" page.
        UserSetupPage."Allow Posting To".AssertEquals(WorkDate - 1);
        UserSetupPage.Close;

        // [WHEN] DrillDown on "Description"
        PurchInvoicePage.Trap;
        LibraryErrorMessage.DrillDownOnContext();
        // [THEN] opens "Purchase Invoice" page.
        PurchInvoicePage."Posting Date".AssertEquals(WorkDate);

        // TearDown
        UserSetup.Delete();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T900_PreviewWithOneLoggedAndOneDirectError()
    var
        PurchHeader: Record "Purchase Header";
        TempErrorMessage: Record "Error Message" temporary;
    begin
        // [FEATURE] [Preview]
        // [SCENARIO] Failed posting preview opens "Error Messages" page that contains two lines: one logged and one directly thrown error.
        Initialize;

        // [GIVEN] "Allow Posting To" is 31.12.2018 in "General Ledger Setup"
        LibraryERM.SetAllowPostingFromTo(0D, WorkDate - 1);
        // [GIVEN] Order '1002', where "Posting Date" is 01.01.2019
        LibraryPurchase.CreatePurchHeader(
          PurchHeader, PurchHeader."Document Type"::Order, LibraryPurchase.CreateVendorNo);

        // [WHEN] Preview Posting of Purchase Order '1002'
        asserterror PreviewPurchDocument(PurchHeader);

        // [THEN] Error message is <blank>
        Assert.ExpectedError('');
        // [THEN] Opened page "Error Messages" with two lines:
        LibraryErrorMessage.GetErrorMessages(TempErrorMessage);
        Assert.RecordCount(TempErrorMessage, 2);
        // [THEN] Second line, where Description is 'There is nothing to post', Context is 'Purchase Header: Order, 1002'
        TempErrorMessage.FindLast;
        TempErrorMessage.TestField(Description, NothingToPostErr);
        TempErrorMessage.TestField("Context Record ID", PurchHeader.RecordId);
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
    [Scope('OnPrem')]
    procedure T940_BatchPostingWithOneLoggedAndOneDirectError()
    var
        PurchHeader: array[3] of Record "Purchase Header";
        TempErrorMessage: Record "Error Message" temporary;
        PurchBatchPostMgt: Codeunit "Purchase Batch Post Mgt.";
        VendorNo: Code[20];
        RegisterID: Guid;
    begin
        // [FEATURE] [Batch Posting]
        // [SCENARIO] Batch posting of two documents (in current session) opens "Error Messages" page that contains two lines per document.
        Initialize;
        LibraryPurchase.SetPostWithJobQueue(false);
        // [GIVEN] "Allow Posting To" is 31.12.2018 in "General Ledger Setup"
        LibraryERM.SetAllowPostingFromTo(0D, WorkDate - 1);
        // [GIVEN] Order '1002', where "Posting Date" is 01.01.2019, and nothing to post
        VendorNo := LibraryPurchase.CreateVendorNo;
        LibraryPurchase.CreatePurchHeader(PurchHeader[1], PurchHeader[1]."Document Type"::Order, VendorNo);
        PurchHeaderToPost(PurchHeader[1]);
        // [GIVEN] Invoice '1003', where "Posting Date" is 01.01.2019
        LibraryPurchase.CreatePurchaseInvoiceForVendorNo(PurchHeader[2], VendorNo);

        // [WHEN] Post both documents as a batch
        LibraryErrorMessage.TrapErrorMessages;
        PurchHeader[3].SetRange("Buy-from Vendor No.", VendorNo);
        PurchBatchPostMgt.RunWithUI(PurchHeader[3], 2, '');

        // [THEN] Opened page "Error Messages" with 3 lines:
        // [THEN] 2 lines for Order '1002' and 1 line for Invoice '1003'
        LibraryErrorMessage.GetErrorMessages(TempErrorMessage);
        Assert.RecordCount(TempErrorMessage, 3);
        // [THEN] The first error for Order '1002' is 'Posting Date is not within your range of allowed posting dates.'
        Clear(RegisterID);
        TempErrorMessage.Get(1);
        Assert.ExpectedMessage(PostingDateNotAllowedErr, TempErrorMessage.Description);
        Assert.AreEqual(PurchHeader[1].RecordId, TempErrorMessage."Context Record ID", 'Context for 1st error');
        // [THEN] The second error for Order '1002' is 'There is nothing to post'
        TempErrorMessage.Get(2);
        Assert.ExpectedMessage(NothingToPostErr, TempErrorMessage.Description);
        Assert.AreEqual(PurchHeader[1].RecordId, TempErrorMessage."Context Record ID", 'Context for 2nd error');
        // [THEN] The Error for Invoice '1003' is 'Posting Date is not within your range of allowed posting dates.'
        TempErrorMessage.Get(3);
        Assert.ExpectedMessage(PostingDateNotAllowedErr, TempErrorMessage.Description);
        Assert.AreEqual(PurchHeader[2].RecordId, TempErrorMessage."Context Record ID", 'Context for 3rd error');
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
    [Scope('OnPrem')]
    procedure T950_BatchPostingWithOneLoggedAndOneDirectErrorBackground()
    var
        PurchHeader: array[3] of Record "Purchase Header";
        ErrorMessage: Record "Error Message";
        JobQueueEntry: Record "Job Queue Entry";
        DimensionValue: Record "Dimension Value";
        DefaultDimension: Record "Default Dimension";
        PurchBatchPostMgt: Codeunit "Purchase Batch Post Mgt.";
        LibraryJobQueue: Codeunit "Library - Job Queue";
        LibraryDimension: Codeunit "Library - Dimension";
        VendorNo: Code[20];
        RegisterID: Guid;
    begin
        // [FEATURE] [Batch Posting] [Job Queue]
        // [SCENARIO] Batch posting of two documents (in background) verifies "Error Messages" that contains two lines per first document and one line for second document
        Initialize;
        LibraryPurchase.SetPostWithJobQueue(true);
        BindSubscription(LibraryJobQueue);
        LibraryJobQueue.SetDoNotHandleCodeunitJobQueueEnqueueEvent(true);

        // [GIVEN] "Allow Posting To" is 31.12.2018 in "General Ledger Setup"
        LibraryERM.SetAllowPostingFromTo(0D, WorkDate - 1);
        // [GIVEN] Invoice '1002', where "Posting Date" is 01.01.2019, and no mandatory dimension
        VendorNo := LibraryPurchase.CreateVendorNo;
        LibraryPurchase.CreatePurchaseInvoiceForVendorNo(PurchHeader[1], VendorNo);
        LibraryDimension.CreateDimWithDimValue(DimensionValue);
        LibraryDimension.CreateDefaultDimensionVendor(DefaultDimension, VendorNo, DimensionValue."Dimension Code", DimensionValue.Code);
        DefaultDimension."Value Posting" := DefaultDimension."Value Posting"::"Code Mandatory";
        DefaultDimension.Modify();
        // [GIVEN] Invoice '1003', where "Posting Date" is 01.01.2019
        LibraryPurchase.CreatePurchaseInvoiceForVendorNo(PurchHeader[2], VendorNo);

        // [WHEN] Post both documents as a batch
        JobQueueEntry.DeleteAll();
        PurchHeader[3].SetRange("Buy-from Vendor No.", VendorNo);
        PurchBatchPostMgt.RunWithUI(PurchHeader[3], 2, '');
        JobQueueEntry.FindSet();
        repeat
            JobQueueEntry.Status := JobQueueEntry.Status::Ready;
            JobQueueEntry.Modify();
            asserterror LibraryJobQueue.RunJobQueueDispatcher(JobQueueEntry);
            LibraryJobQueue.RunJobQueueErrorHandler(JobQueueEntry);
        until JobQueueEntry.Next() = 0;

        // [THEN] "Error Message" table contains 3 lines:
        // [THEN] 2 lines for Invoice '1002' and 1 line for Invoice '1003'
        // [THEN] The first error for Invoice '1002' is 'Posting Date is not within your range of allowed posting dates.'
        ErrorMessage.SetRange("Context Record ID", PurchHeader[1].RecordId);
        Assert.RecordCount(ErrorMessage, 2);
        ErrorMessage.FindFirst();
        Assert.ExpectedMessage(PostingDateNotAllowedErr, ErrorMessage.Description);
        // [THEN] The second error for Invoice '1002' is 'Select a Dimension Value Code for the Dimension Code %1 for Customer %2.'
        ErrorMessage.Next();
        Assert.ExpectedMessage(StrSubstNo(DefaultDimErr, DefaultDimension."Dimension Code", VendorNo), ErrorMessage.Description);

        // [THEN] The Error for Invoice '1003' is 'Posting Date is not within your range of allowed posting dates.'
        ErrorMessage.SetRange("Context Record ID", PurchHeader[2].RecordId);
        Assert.RecordCount(ErrorMessage, 1);
        ErrorMessage.FindFirst();
        Assert.ExpectedMessage(PostingDateNotAllowedErr, ErrorMessage.Description);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostingReceivingNoConflictErrorHandling()
    var
        ErrorMessage: Record "Error Message";
        PurchHeader: Record "Purchase Header";
        PurchRcptHeader: Record "Purch. Rcpt. Header";
        PurchSetup: Record "Purchases & Payables Setup";
        NoSeriesLine: Record "No. Series Line";
        LastNoUsed: Text;
        OriginalNoSeriesLine: Record "No. Series Line";
    begin
        // [SCENARIO] Should properly handle posting purchase invoice when the reserved Receiving No. is already existing.
        // This can occur when a user manually changes the Last No. Used of the No Series Line such that the next number
        // to use has already been used.
        Initialize();
        LibraryERM.SetAllowPostingFromTo(0D, WorkDate);
        PurchSetup.Get();
        PurchSetup."Receipt on Invoice" := true;
        PurchSetup.Modify();
        LibraryErrorMessage.TrapErrorMessages();

        // [GIVEN] Purchase invoice where we create a Purch. Rcpt. Header record and the next Receiving No. already exists.
        LibraryPurchase.CreatePurchaseInvoice(PurchHeader);

        // Use No. Series from purchases setup.
        PurchHeader."Receiving No. Series" := PurchSetup."Posted Receipt Nos.";
        LibraryUtility.GetNoSeriesLine(PurchHeader."Receiving No. Series", NoSeriesLine);

        // Store original values for tear down.
        OriginalNoSeriesLine.TransferFields(NoSeriesLine, false);

        PurchRcptHeader.SetCurrentKey("No.");
        PurchRcptHeader.FindFirst();
        LastNoUsed := LibraryUtility.DecStr(PurchRcptHeader."No.");

        // Sanity check.
        Assert.AreEqual(PurchRcptHeader."No.", IncStr(LastNoUsed), 'DecStr gave incorrect result.');

        NoSeriesLine."Starting No." := LastNoUsed;
        NoSeriesLine."Last No. Used" := LastNoUsed;
        NoSeriesLine."Ending No." := IncStr(IncStr(LastNoUsed));
        NoSeriesLine."Warning No." := NoSeriesLine."Ending No.";
        NoSeriesLine.Modify();

        // [WHEN] Posting purchase invoice.
        PurchHeader.SendToPosting(CODEUNIT::"Purch.-Post");

        // [THEN] An error is thrown.
        ErrorMessage.SetRange("Context Record ID", PurchHeader.RecordId);
        Assert.RecordCount(ErrorMessage, 1);
        ErrorMessage.FindFirst();
        ErrorMessage.TestField(Description, StrSubstNo(PurchRcptHeaderConflictErr, IncStr(LastNoUsed)));

        // [THEN] The Purchase Header field Receiving No. is blank.
        PurchHeader.Get(PurchHeader."Document Type", PurchHeader."No.");
        Assert.AreEqual('', PurchHeader."Receiving No.", 'Receiving No. was not blank.');

        // TearDown: Reset No Series. Line.
        NoSeriesLine.TransferFields(OriginalNoSeriesLine, false);
        NoSeriesLine.Modify();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostingReturnShipmentNoConflictErrorHandling()
    var
        ErrorMessage: Record "Error Message";
        PurchHeader: Record "Purchase Header";
        ReturnShptHeader: Record "Return Shipment Header";
        PurchSetup: Record "Purchases & Payables Setup";
        NoSeriesLine: Record "No. Series Line";
        LastNoUsed: Text;
        OriginalNoSeriesLine: Record "No. Series Line";
    begin
        // [SCENARIO] Should properly handle posting purchase return order when the reserved Return Shipment No. is already existing.
        // This can occur when a user manually changes the Last No. Used of a No Series Line such that the next number
        // to use has already been used.
        Initialize();
        LibraryERM.SetAllowPostingFromTo(0D, WorkDate);
        LibraryErrorMessage.TrapErrorMessages();

        // [GIVEN] Purchase return order where we create a Return Shipment Header record and the next Return Shipment No. already exists.
        LibraryPurchase.CreatePurchaseReturnOrder(PurchHeader);
        PurchHeader.Ship := true;

        // Use No. Series from purchases setup.
        PurchSetup.Get();
        PurchHeader."Return Shipment No. Series" := PurchSetup."Posted Return Shpt. Nos.";
        LibraryUtility.GetNoSeriesLine(PurchHeader."Return Shipment No. Series", NoSeriesLine);

        // Store original values for tear down.
        OriginalNoSeriesLine.TransferFields(NoSeriesLine, false);

        ReturnShptHeader.SetCurrentKey("No.");
        ReturnShptHeader.FindFirst();
        LastNoUsed := LibraryUtility.DecStr(ReturnShptHeader."No.");

        // Sanity check.
        Assert.AreEqual(ReturnShptHeader."No.", IncStr(LastNoUsed), 'DecStr gave incorrect result.');

        NoSeriesLine."Starting No." := LastNoUsed;
        NoSeriesLine."Last No. Used" := LastNoUsed;
        NoSeriesLine."Ending No." := IncStr(IncStr(LastNoUsed));
        NoSeriesLine."Warning No." := NoSeriesLine."Ending No.";
        NoSeriesLine.Modify();

        // [WHEN] Posting purchase return order.
        PurchHeader.SendToPosting(CODEUNIT::"Purch.-Post");

        // [THEN] An error is thrown.
        ErrorMessage.SetRange("Context Record ID", PurchHeader.RecordId);
        Assert.RecordCount(ErrorMessage, 1);
        ErrorMessage.FindFirst();
        ErrorMessage.TestField(Description, StrSubstNo(ReturnShptHeaderConflictErr, IncStr(LastNoUsed)));

        // [THEN] The Purchase Header field Return Shipment No. is blank.
        PurchHeader.Get(PurchHeader."Document Type", PurchHeader."No.");
        Assert.AreEqual('', PurchHeader."Return Shipment No.", 'Return Shipment No. was not blank.');

        // TearDown: Reset No Series. Line.
        NoSeriesLine.TransferFields(OriginalNoSeriesLine, false);
        NoSeriesLine.Modify();
    end;


    [Test]
    [Scope('OnPrem')]
    procedure PostingInvoicePostingNoConflictErrorHandling()
    var
        ErrorMessage: Record "Error Message";
        PurchHeader: Record "Purchase Header";
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchSetup: Record "Purchases & Payables Setup";
        NoSeriesLine: Record "No. Series Line";
        LastNoUsed: Text;
        OriginalNoSeriesLine: Record "No. Series Line";
    begin
        // [SCENARIO] Should properly handle posting purchase invoice when the reserved Posting No. is already existing.
        // This can occur when a user manually changes the Last No. Used of the No Series Line such that the next number
        // to use has already been used.
        Initialize();
        LibraryERM.SetAllowPostingFromTo(0D, WorkDate);
        LibraryErrorMessage.TrapErrorMessages();

        // [GIVEN] Purchase invoice where we create a Purch. Inv. Header record and the next Posting No. already exists.
        LibraryPurchase.CreatePurchaseInvoice(PurchHeader);

        // Use No. Series from purchases setup.
        PurchSetup.Get();
        PurchHeader."Posting No. Series" := PurchSetup."Posted Invoice Nos.";
        LibraryUtility.GetNoSeriesLine(PurchHeader."Posting No. Series", NoSeriesLine);

        // Store original values for tear down.
        OriginalNoSeriesLine.TransferFields(NoSeriesLine, false);

        PurchInvHeader.SetCurrentKey("No.");
        PurchInvHeader.FindFirst();
        LastNoUsed := LibraryUtility.DecStr(PurchInvHeader."No.");

        // Sanity check.
        Assert.AreEqual(PurchInvHeader."No.", IncStr(LastNoUsed), 'DecStr gave incorrect result.');

        NoSeriesLine."Starting No." := LastNoUsed;
        NoSeriesLine."Last No. Used" := LastNoUsed;
        NoSeriesLine."Ending No." := IncStr(IncStr(LastNoUsed));
        NoSeriesLine."Warning No." := NoSeriesLine."Ending No.";
        NoSeriesLine.Modify();

        // [WHEN] Posting purchase order.
        PurchHeader.SendToPosting(CODEUNIT::"Purch.-Post");

        // [THEN] An error is thrown.
        ErrorMessage.SetRange("Context Record ID", PurchHeader.RecordId);
        Assert.RecordCount(ErrorMessage, 1);
        ErrorMessage.FindFirst();
        ErrorMessage.TestField(Description, StrSubstNo(PurchInvHeaderConflictErr, IncStr(LastNoUsed)));

        // [THEN] The Purchase Header field Posting No. is blank.
        PurchHeader.Get(PurchHeader."Document Type", PurchHeader."No.");
        Assert.AreEqual('', PurchHeader."Posting No.", 'Posting No. was not blank.');

        // TearDown: Reset No Series. Line.
        NoSeriesLine.TransferFields(OriginalNoSeriesLine, false);
        NoSeriesLine.Modify();
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Purch. Document Posting Errors");
        LibraryErrorMessage.Clear;
        LibrarySetupStorage.Restore;
        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"Purch. Document Posting Errors");
        LibrarySetupStorage.Save(DATABASE::"General Ledger Setup");
        LibrarySetupStorage.Save(DATABASE::"Purchases & Payables Setup");

        IsInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"Purch. Document Posting Errors");
    end;

    local procedure PreviewPurchDocument(PurchHeader: Record "Purchase Header")
    var
        PurchPostYesNo: Codeunit "Purch.-Post (Yes/No)";
    begin
        PurchHeaderToPost(PurchHeader);
        LibraryErrorMessage.TrapErrorMessages;
        PurchPostYesNo.Preview(PurchHeader);
    end;

    local procedure PurchHeaderToPost(var PurchHeader: Record "Purchase Header")
    begin
        PurchHeader.Receive := true;
        PurchHeader.Invoice := true;
        PurchHeader.Modify();
        Commit();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmYesHandler(Question: Text; var Reply: Boolean)
    begin
        Reply := true;
    end;
}

