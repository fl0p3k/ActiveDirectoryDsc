# culture="en-US"
ConvertFrom-StringData @'
    QueryingFineGrainedPasswordPolicy               = Querying policy '{0}'. (ADFGPP0001)
    UpdatingFineGrainedPasswordPolicy               = Updating policy '{0}'. (ADFGPP0002)
    CreatingFineGrainedPasswordPolicy               = Creating policy '{0}'. (ADFGPP0003)
    RemovingFineGrainedPasswordPolicy               = Removing policy '{0}'. (ADFGPP0004)
    SettingPasswordPolicyValue                      = Setting policy '{0}' property to '{1}'. (ADFGPP0005)
    ResourceInDesiredState                          = Policy '{0}' is in the desired state. (ADFGPP0006)
    ResourceNotInDesiredState                       = Policy '{0}' is not in the desired state. (ADFGPP0007)
    ResourceConfigurationError                      = Error setting policy '{0}'. (ADFGPP0008)
    RetrieveFineGrainedPasswordPolicyError          = Error retrieving policy '{0}'. (ADFGPP0009)
    RetrieveFineGrainedPasswordPolicySubjectError   = Error retrieving policy subject '{0}'. (ADFGPP0010)
    ResourceExistsButShouldNotMessage               = Policy '{0}' exists but should not. (ADFGPP0011)
    ResourceDoesNotExistButShouldMessage            = Policy '{0}' does not exist but should. (ADFGPP0012)
    ProtectedFromAccidentalDeletionRemove           = Attempting to remove the protection for accidental deletion. (ADFGPP0013)
    ProtectedFromAccidentalDeletionUndefined        = ProtectedFromAccidentalDeletion is not defined to false for policy {0}. Delete may fail if not explicitly set false. (ADFGPP0014)
    AddingNewSubjects                               = Adding new subjects to policy '{0}', count '{1}'. (ADFGPP0015)
    RemovingExistingSubjects                        = Removing existing subjects from policy '{0}', count '{1}'. (ADFGPP0016)
'@
