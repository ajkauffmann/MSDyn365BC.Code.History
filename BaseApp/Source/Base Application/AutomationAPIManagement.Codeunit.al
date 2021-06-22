codeunit 5435 "Automation - API Management"
{
    EventSubscriberInstance = Manual;

    trigger OnRun()
    begin
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"SaaS Log In Management", 'OnSuppressApprovalForTrial', '', false, false)]
    local procedure OnSuppressApprovalForTrial(var GetSuppressApprovalForTrial: Boolean)
    begin
        GetSuppressApprovalForTrial := true;
    end;
}

