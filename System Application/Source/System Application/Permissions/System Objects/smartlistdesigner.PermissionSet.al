permissionset 7379 "SMARTLIST DESIGNER"
{
    Access = Public;
    Assignable = true;
    Caption = 'SmartList Designer';

    Permissions = system "SmartList Designer API" = X,
                  system "SmartList Designer Preview" = X,
                  system "SmartList Import/Export" = X,
                  system "SmartList Management" = X;
}
