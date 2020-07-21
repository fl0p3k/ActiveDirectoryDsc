$script:resourceModulePath = Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent
$script:modulesFolderPath = Join-Path -Path $script:resourceModulePath -ChildPath 'Modules'

$script:localizationModulePath = Join-Path -Path $script:modulesFolderPath -ChildPath 'ActiveDirectoryDsc.Common'
Import-Module -Name (Join-Path -Path $script:localizationModulePath -ChildPath 'ActiveDirectoryDsc.Common.psm1')

$script:localizedData = Get-LocalizedData -DefaultUICulture 'en-US'

<#
    .SYNOPSIS
        Returns the current state of an Active Directory fine-grained password
        policy.

    .PARAMETER Name
        Specifies an Active Directory fine-grained password policy object name.

    .PARAMETER Precedence
        Specifies a value that defines the precedence of a fine-grained password policy among all fine-grained password
        policies.

    .PARAMETER DomainController
        Specifies the Active Directory Domain Services instance to connect to.

    .PARAMETER Credential
        Specifies the user account credentials to use to perform this task.

    .NOTES
        Used Functions:
            Name                                   | Module
            ---------------------------------------|--------------------------
            Get-ADFineGrainedPasswordPolicy        | ActiveDirectory
            Get-ADFineGrainedPasswordPolicySubject | ActiveDirectory
            Assert-Module                          | DscResource.Common
            New-InvalidOperationException          | DscResource.Common
            Get-ADCommonParameters                 | ActiveDirectoryDsc.Common
#>
function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [Parameter(Mandatory = $true)]
        [System.UInt32]
        $Precedence,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $DomainController,

        [Parameter()]
        [ValidateNotNull()]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.CredentialAttribute()]
        $Credential
    )

    Assert-Module -ModuleName 'ActiveDirectory'

    [HashTable] $parameters = $PSBoundParameters

    $parameters['Identity'] = $Name
    $parameters.Remove('Precedence')

    Write-Verbose -Message ($script:localizedData.QueryingFineGrainedPasswordPolicy -f $Name)

    # Set the filter parameter and remove items not needed
    $getADFineGrainedPasswordPolicyParams = Get-ADCommonParameters @parameters
    $getADFineGrainedPasswordPolicyParams["Filter"] = "name -eq `'$Name`'"
    $getADFineGrainedPasswordPolicyParams.Remove('Identity')

    try
    {
        $policy = Get-ADFineGrainedPasswordPolicy @getADFineGrainedPasswordPolicyParams
    }
    catch
    {
        $errorMessage = $script:localizedData.RetrieveFineGrainedPasswordPolicyError -f $Name
        New-InvalidOperationException -Message $errorMessage -ErrorRecord $_
    }

    [String[]] $policySubjects = ""

    if ($policy)
    {
        $getADFineGrainedPasswordPolicySubjectParams = Get-ADCommonParameters @parameters

        try
        {
            [String[]] $policySubjects = (Get-ADFineGrainedPasswordPolicySubject `
                @getADFineGrainedPasswordPolicySubjectParams).Name
        }
        catch
        {
            $errorMessage = $script:localizedData.RetrieveFineGrainedPasswordPolicySubjectError -f $Name
            New-InvalidOperationException -Message $errorMessage -ErrorRecord $_
        }

        return @{
            Name                        = $Name
            ComplexityEnabled           = $policy.ComplexityEnabled
            LockoutDuration             = $policy.LockoutDuration
            LockoutObservationWindow    = $policy.LockoutObservationWindow
            LockoutThreshold            = $policy.LockoutThreshold
            MinPasswordAge              = $policy.MinPasswordAge
            MaxPasswordAge              = $policy.MaxPasswordAge
            MinPasswordLength           = $policy.MinPasswordLength
            PasswordHistoryCount        = $policy.PasswordHistoryCount
            ReversibleEncryptionEnabled = $policy.ReversibleEncryptionEnabled
            Precedence                  = $policy.Precedence
            Ensure                      = 'Present'
            Subjects                    = $policySubjects
        }
    }
    else
    {
        return @{
            Name                        = $Name
            ComplexityEnabled           = $null
            LockoutDuration             = $null
            LockoutObservationWindow    = $null
            LockoutThreshold            = $null
            MinPasswordAge              = $null
            MaxPasswordAge              = $null
            MinPasswordLength           = $null
            PasswordHistoryCount        = $null
            ReversibleEncryptionEnabled = $null
            Precedence                  = $null
            Ensure                      = 'Absent'
            Subjects                    = $policySubjects
        }
    }
} #end Get-TargetResource

<#
    .SYNOPSIS
        Determines if the Active Directory fine-grained password policy is in
        the desired state

    .PARAMETER Name
        Specifies an Active Directory fine-grained password policy object name.

    .PARAMETER Precedence
        Specifies a value that defines the precedence of a fine-grained password policy among all fine-grained password
        policies.

    .PARAMETER DisplayName
        Specifies the display name of the object.

    .PARAMETER Subjects
        Specifies the ADPrincipal names the policy is to be applied to, overwrites all existing.

    .PARAMETER Ensure
        Specifies whether the fine grained password policy should be present or absent. Default value is 'Present'.

    .PARAMETER ComplexityEnabled
        Specifies whether password complexity is enabled for the password policy.

    .PARAMETER LockoutDuration
        Specifies the length of time that an account is locked after the number of failed login attempts exceeds the
        lockout threshold. The lockout duration must be greater than or equal to the lockout observation time for a
        password policy. The value must be a string representation of a TimeSpan value.

    .PARAMETER LockoutObservationWindow
        Specifies the maximum time interval between two unsuccessful login attempts before the number of unsuccessful
        login attempts is reset to 0. The lockout observation window must be smaller than or equal to the lockout
        duration for a password policy. The value must be a string representation of a TimeSpan value.

    .PARAMETER LockoutThreshold
        Specifies the number of unsuccessful login attempts that are permitted before an account is locked out.

    .PARAMETER MinPasswordAge
        Specifies the minimum length of time before you can change a password. The value must be a string
        representation of a TimeSpan value.

    .PARAMETER MaxPasswordAge
        Specifies the maximum length of time that you can have the same password. The value must be a string
        representation of a TimeSpan value.

    .PARAMETER MinPasswordLength
        Specifies the minimum number of characters that a password must contain.

    .PARAMETER PasswordHistoryCount
        Specifies the number of previous passwords to save.

    .PARAMETER ReversibleEncryptionEnabled
        Specifies whether the directory must store passwords using reversible encryption.

    .PARAMETER ProtectedFromAccidentalDeletion
        Specifies whether to prevent the object from being deleted.

    .PARAMETER DomainController
        Specifies the Active Directory Domain Services instance to connect to.

    .PARAMETER Credential
        Specifies the user account credentials to use to perform this task.

    .NOTES
        Used Functions:
            Name                          | Module
            ------------------------------|--------------------------
            Compare-ResourcePropertyState | ActiveDirectoryDsc.Common
#>
function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [Parameter(Mandatory = $true)]
        [System.UInt32]
        $Precedence,

        [Parameter()]
        [System.String]
        $DisplayName,

        [Parameter()]
        [System.String[]]
        $Subjects,

        [Parameter()]
        [ValidateSet('Present', 'Absent')]
        [System.String]
        $Ensure = 'Present',

        [Parameter()]
        [System.Boolean]
        $ComplexityEnabled,

        [Parameter()]
        [ValidateScript({
            ([ValidateRange(1, 30)]$valueInMinutes = [TimeSpan]::Parse($_).TotalMinutes); $?
        })]
        [String]
        $LockoutDuration,

        [Parameter()]
        [ValidateScript({
            ([ValidateRange(1, 30)]$valueInMinutes = [TimeSpan]::Parse($_).TotalMinutes); $?
        })]
        [String]
        $LockoutObservationWindow,

        [Parameter()]
        [System.UInt32]
        $LockoutThreshold,

        [Parameter()]
        [ValidateScript({
            ([ValidateRange(1, 10675199)]$valueInDays = [TimeSpan]::Parse($_).TotalDays); $?
        })]
        [String]
        $MinPasswordAge,

        [Parameter()]
        [ValidateScript({
            ([ValidateRange(1, 10675199)]$valueInDays = [TimeSpan]::Parse($_).TotalDays); $?
        })]
        [String]
        $MaxPasswordAge,

        [Parameter()]
        [System.UInt32]
        $MinPasswordLength,

        [Parameter()]
        [System.UInt32]
        $PasswordHistoryCount,

        [Parameter()]
        [System.Boolean]
        $ReversibleEncryptionEnabled,

        [Parameter()]
        [System.Boolean]
        $ProtectedFromAccidentalDeletion,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $DomainController,

        [Parameter()]
        [ValidateNotNull()]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.CredentialAttribute()]
        $Credential
    )

    # Need to set these parameters to compare if users are using the default parameter values
    [HashTable] $parameters = $PSBoundParameters

    $getTargetResourceParams = @{
        Name       = $Name
        Precedence = $Precedence
    }

    # Build parameters needed to get resource properties
    if ($parameters.ContainsKey('Credential'))
    {
        $getTargetResourceParams['Credential'] = $Credential
    }

    if ($parameters.ContainsKey('DomainController'))
    {
        $getTargetResourceParams['DomainController'] = $DomainController
    }

    $getTargetResourceResult = Get-TargetResource @getTargetResourceParams
    $inDesiredState = $true

    if ($getTargetResourceResult.Ensure -eq 'Present')
    {
        if ($Ensure -eq 'Present')
        {
            # Resource should exist
            $propertiesNotInDesiredState = (
                Compare-ResourcePropertyState -CurrentValues $getTargetResourceResult -DesiredValues $parameters `
                    -IgnoreProperties 'Name', 'Identity', 'DisplayName', 'ProtectedFromAccidentalDeletion', `
                    'Credential', 'DomainController' | Where-Object -Property InDesiredState -eq $false)

            if ($propertiesNotInDesiredState)
            {
                $inDesiredState = $false
            }
            else
            {
                # Resource is in desired state
                Write-Verbose -Message ($script:localizedData.ResourceInDesiredState -f $Name)
                $inDesiredState = $true
            }
        }
        else
        {
            # Resource should not exist
            Write-Verbose -Message ($script:localizedData.ResourceExistsButShouldNotMessage -f $Name)
            $inDesiredState = $false
        }
    }
    else
    {
        # Resource does not exist
        if ($Ensure -eq 'Present')
        {
            # Resource should exist
            Write-Verbose -Message ($script:localizedData.ResourceDoesNotExistButShouldMessage -f $Name)
            $inDesiredState = $false
        }
        else
        {
            # Resource should not exist
            $inDesiredState = $true
        }
    }

    if ($inDesiredState)
    {
        Write-Verbose -Message ($script:localizedData.ResourceInDesiredState -f $Name)
        return $true
    }
    else
    {
        Write-Verbose -Message ($script:localizedData.ResourceNotInDesiredState -f $Name)
        return $false
    }
} #end Test-TargetResource

<#
    .SYNOPSIS
        Modifies the Active Directory fine-grained password policy.

    .PARAMETER Name
        Specifies an Active Directory fine-grained password policy object name.

    .PARAMETER Precedence
        Specifies a value that defines the precedence of a fine-grained password policy among all fine-grained password
        policies.

    .PARAMETER DisplayName
        Specifies the display name of the object.

    .PARAMETER Subjects
        Specifies the ADPrincipal names the policy is to be applied to, overwrites all existing.

    .PARAMETER Ensure
        Specifies whether the fine grained password policy should be present or absent. Default value is 'Present'.

    .PARAMETER ComplexityEnabled
        Specifies whether password complexity is enabled for the password policy.

    .PARAMETER LockoutDuration
        Specifies the length of time that an account is locked after the number of failed login attempts exceeds the
        lockout threshold. The lockout duration must be greater than or equal to the lockout observation time for a
        password policy. The value must be a string representation of a TimeSpan value.

    .PARAMETER LockoutObservationWindow
        Specifies the maximum time interval between two unsuccessful login attempts before the number of unsuccessful
        login attempts is reset to 0. The lockout observation window must be smaller than or equal to the lockout
        duration for a password policy. The value must be a string representation of a TimeSpan value.

    .PARAMETER LockoutThreshold
        Specifies the number of unsuccessful login attempts that are permitted before an account is locked out.

    .PARAMETER MinPasswordAge
        Specifies the minimum length of time before you can change a password. The value must be a string
        representation of a TimeSpan value.

    .PARAMETER MaxPasswordAge
        Specifies the maximum length of time that you can have the same password. The value must be a string
        representation of a TimeSpan value.

    .PARAMETER MinPasswordLength
        Specifies the minimum number of characters that a password must contain.

    .PARAMETER PasswordHistoryCount
        Specifies the number of previous passwords to save.

    .PARAMETER ReversibleEncryptionEnabled
        Specifies whether the directory must store passwords using reversible encryption.

    .PARAMETER ProtectedFromAccidentalDeletion
        Specifies whether to prevent the object from being deleted.

    .PARAMETER DomainController
        Specifies the Active Directory Domain Services instance to connect to.

    .PARAMETER Credential
        Specifies the user account credentials to use to perform this task.

    .NOTES
        Used Functions:
            Name                                      | Module
            ------------------------------------------|--------------------------
            New-ADFineGrainedPasswordPolicy           | ActiveDirectory
            Set-ADFineGrainedPasswordPolicy           | ActiveDirectory
            Remove-ADFineGrainedPasswordPolicy        | ActiveDirectory
            Add-ADFineGrainedPasswordPolicySubject    | ActiveDirectory
            Remove-ADFineGrainedPasswordPolicySubject | ActiveDirectory
            Assert-Module                             | DscResource.Common
            New-InvalidOperationException             | DscResource.Common
            Get-ADCommonParameters                    | ActiveDirectoryDsc.Common
            Compare-ResourcePropertyState             | ActiveDirectoryDsc.Common
#>
function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [Parameter(Mandatory = $true)]
        [System.UInt32]
        $Precedence,

        [Parameter()]
        [System.String]
        $DisplayName,

        [Parameter()]
        [System.String[]]
        $Subjects,

        [Parameter()]
        [ValidateSet('Present', 'Absent')]
        [System.String]
        $Ensure = 'Present',

        [Parameter()]
        [System.Boolean]
        $ComplexityEnabled,

        [Parameter()]
        [ValidateScript({
            ([ValidateRange(1, 30)]$valueInMinutes = [TimeSpan]::Parse($_).TotalMinutes); $?
        })]
        [String]
        $LockoutDuration,

        [Parameter()]
        [ValidateScript({
            ([ValidateRange(1, 30)]$valueInMinutes = [TimeSpan]::Parse($_).TotalMinutes); $?
        })]
        [String]
        $LockoutObservationWindow,

        [Parameter()]
        [System.UInt32]
        $LockoutThreshold,

        [Parameter()]
        [ValidateScript({
            ([ValidateRange(1, 10675199)]$valueInDays = [TimeSpan]::Parse($_).TotalDays); $?
        })]
        [String]
        $MinPasswordAge,

        [Parameter()]
        [ValidateScript({
            ([ValidateRange(1, 10675199)]$valueInDays = [TimeSpan]::Parse($_).TotalDays); $?
        })]
        [String]
        $MaxPasswordAge,

        [Parameter()]
        [System.UInt32]
        $MinPasswordLength,

        [Parameter()]
        [System.UInt32]
        $PasswordHistoryCount,

        [Parameter()]
        [System.Boolean]
        $ReversibleEncryptionEnabled,

        [Parameter()]
        [System.Boolean]
        $ProtectedFromAccidentalDeletion,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $DomainController,

        [Parameter()]
        [ValidateNotNull()]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.CredentialAttribute()]
        $Credential
    )

    # Need to set these to compare if not specified since user is using defaults
    [HashTable] $parameters = $PSBoundParameters

    Assert-Module -ModuleName 'ActiveDirectory'

    $commonParams = @{
        Identity = $Name
    }

    if ($parameters.ContainsKey('Credential'))
    {
        $commonParams['Credential'] = $Credential
    }

    if ($parameters.ContainsKey('DomainController'))
    {
        $commonParams['DomainController'] = $DomainController
    }

    $getTargetResourceParams = $commonParams.Clone()
    $getTargetResourceParams.Remove('Identity')
    $getTargetResourceParams['Name'] = $Name
    $getTargetResourceParams['Precedence'] = $Precedence

    $getTargetResourceResult = Get-TargetResource @getTargetResourceParams

    $parameters['Identity'] = $Name

    if ($getTargetResourceResult.Ensure -eq 'Present')
    {
        $setADFineGrainedPasswordPolicyParams = Get-ADCommonParameters @parameters
    }
    else
    {
        $newADFineGrainedPasswordPolicyParams = Get-ADCommonParameters @parameters -UseNameParameter
    }

    $commonADFineGrainedPasswordPolicyParams = Get-ADCommonParameters @commonParams

    if ($Ensure -eq 'Present')
    {
        # Resource should be present and set correctly
        if ($getTargetResourceResult.Ensure -eq 'Present')
        {
            # Resource exists and should be in desired state
            $propertiesNotInDesiredState = (
                Compare-ResourcePropertyState -CurrentValues $getTargetResourceResult -DesiredValues $parameters `
                    -IgnoreProperties 'Name', 'Identity', 'DisplayName', 'ProtectedFromAccidentalDeletion', `
                    'Credential', 'DomainController' | Where-Object -Property InDesiredState -eq $false)

            if ($propertiesNotInDesiredState)
            {
                # Resource is present not in desired state

                $updateSubjects = $false

                Write-Verbose -Message ($script:localizedData.UpdatingFineGrainedPasswordPolicy -f $Name)

                # Build parameters needed to set resource properties
                foreach ($property in $propertiesNotInDesiredState)
                {
                    if ($property.ParameterName -eq 'Subjects')
                    {
                        $updateSubjects = $true
                    }
                    else
                    {
                        $setADFineGrainedPasswordPolicyParams[$property.ParameterName] = $property.Expected

                        Write-Verbose -Message ($script:localizedData.SettingPasswordPolicyValue -f
                            $property.ParameterName, $property.Expected)
                    }
                }

                if ($PSBoundParameters.ContainsKey('DisplayName'))
                {
                    $setADFineGrainedPasswordPolicyParams['DisplayName'] = $DisplayName
                    Write-Verbose -Message ($script:localizedData.SettingPasswordPolicyValue -f
                        'DisplayName', $DisplayName)
                }

                if ($PSBoundParameters.ContainsKey('ProtectedFromAccidentalDeletion'))
                {
                    $setADFineGrainedPasswordPolicyParams['ProtectedFromAccidentalDeletion'] = $ProtectedFromAccidentalDeletion
                    Write-Verbose -Message ($script:localizedData.SettingPasswordPolicyValue -f
                        'ProtectedFromAccidentalDeletion', $ProtectedFromAccidentalDeletion)
                }

                try
                {
                    Set-ADFineGrainedPasswordPolicy @setADFineGrainedPasswordPolicyParams
                }
                catch
                {
                    $errorMessage = $script:localizedData.ResourceConfigurationError -f $Name
                    New-InvalidOperationException -Message $errorMessage -ErrorRecord $_
                }

                # Add the exclusive subjects to policy (removes all others)
                if ($updateSubjects)
                {
                    $getExistingSubjectsToRemove = Get-ADFineGrainedPasswordPolicySubject `
                        @commonADFineGrainedPasswordPolicyParams

                    if ($getExistingSubjectsToRemove)
                    {
                        Write-Verbose -Message ($script:localizedData.RemovingExistingSubjects -f
                            $Name, $($getExistingSubjectsToRemove.Count))

                        try
                        {
                            Remove-ADFineGrainedPasswordPolicySubject @commonADFineGrainedPasswordPolicyParams `
                                -Subjects $getExistingSubjectsToRemove -Confirm:$false
                        }
                        catch
                        {
                            $errorMessage = $script:localizedData.ResourceConfigurationError -f $Name
                            New-InvalidOperationException -Message $errorMessage -ErrorRecord $_
                        }
                    }

                    Write-Verbose -Message ($script:localizedData.AddingNewSubjects -f $Name, $($Subjects.Count))

                    try
                    {
                        Add-ADFineGrainedPasswordPolicySubject @commonADFineGrainedPasswordPolicyParams `
                            -Subjects $Subjects
                    }
                    catch
                    {
                        $errorMessage = $script:localizedData.ResourceConfigurationError -f $Name
                        New-InvalidOperationException -Message $errorMessage -ErrorRecord $_
                    }
                }
            }
            else
            {
                # Resource is in desired state
                Write-Verbose -Message ($script:localizedData.ResourceInDesiredState -f $Name)
            }
        }
        else
        {
            # Resource should exist
            Write-Verbose -Message ($script:localizedData.ResourceDoesNotExistButShouldMessage -f $Name)

            Write-Verbose -Message ($script:localizedData.CreatingFineGrainedPasswordPolicy -f $Name)

            $propertiesNotInDesiredState = (
                Compare-ResourcePropertyState -CurrentValues $getTargetResourceResult -DesiredValues $parameters `
                    -IgnoreProperties 'Name', 'Identity', 'DisplayName', 'ProtectedFromAccidentalDeletion', `
                    'Credential', 'DomainController', 'Ensure' | Where-Object -Property InDesiredState -eq $false)

            # Build parameters needed to set resource properties

            $createSubjects = $false

            foreach ($property in $propertiesNotInDesiredState)
            {
                if ($property.ParameterName -eq 'Subjects')
                {
                    $createSubjects = $true
                }
                else
                {
                    $newADFineGrainedPasswordPolicyParams[$property.ParameterName] = $property.Expected

                    Write-Verbose -Message ($script:localizedData.SettingPasswordPolicyValue -f
                        $property.ParameterName, $property.Expected)
                }
            }

            if ($PSBoundParameters.ContainsKey('DisplayName'))
            {
                $newADFineGrainedPasswordPolicyParams['DisplayName'] = $DisplayName
                Write-Verbose -Message ($script:localizedData.SettingPasswordPolicyValue -f
                    'DisplayName', $DisplayName)
            }

            if ($PSBoundParameters.ContainsKey('ProtectedFromAccidentalDeletion'))
            {
                $newADFineGrainedPasswordPolicyParams['ProtectedFromAccidentalDeletion'] = $ProtectedFromAccidentalDeletion
                Write-Verbose -Message ($script:localizedData.SettingPasswordPolicyValue -f
                    'ProtectedFromAccidentalDeletion', $ProtectedFromAccidentalDeletion)
            }

            try
            {
                New-ADFineGrainedPasswordPolicy @newADFineGrainedPasswordPolicyParams
            }
            catch
            {
                $errorMessage = $script:localizedData.ResourceConfigurationError -f $Name
                New-InvalidOperationException -Message $errorMessage -ErrorRecord $_
            }

            if ($createSubjects)
            {
                try
                {
                    Add-ADFineGrainedPasswordPolicySubject @commonADFineGrainedPasswordPolicyParams -Subjects $Subjects
                }
                catch
                {
                    $errorMessage = $script:localizedData.ResourceConfigurationError -f $Name
                    New-InvalidOperationException -Message $errorMessage -ErrorRecord $_
                }
            }
        }
    }
    else
    {
        # Resource should not exist

        if ($getTargetResourceResult.Ensure -eq 'Present')
        {
            # Resource exists but shouldn't

            Write-Verbose -Message ($script:localizedData.ResourceExistsButShouldNotMessage -f $Name)

            if ($parameters.ContainsKey('ProtectedFromAccidentalDeletion') -and `
                -not $ProtectedFromAccidentalDeletion)
            {
                Write-Verbose -Message ($script:localizedData.ProtectedFromAccidentalDeletionRemove)

                try
                {
                    Set-ADFineGrainedPasswordPolicy @commonADFineGrainedPasswordPolicyParams `
                        -ProtectedFromAccidentalDeletion $ProtectedFromAccidentalDeletion
                }
                catch
                {
                    $errorMessage = $script:localizedData.ResourceConfigurationError -f $Name
                    New-InvalidOperationException -Message $errorMessage -ErrorRecord $_
                }
            }
            else
            {
                Write-Verbose -Message ($script:localizedData.ProtectedFromAccidentalDeletionUndefined -f $Name)
            }

            Write-Verbose -Message ($script:localizedData.RemovingFineGrainedPasswordPolicy -f $Name)

            try
            {
                Remove-ADFineGrainedPasswordPolicy @commonADFineGrainedPasswordPolicyParams
            }
            catch
            {
                $errorMessage = $script:localizedData.ResourceConfigurationError -f $Name
                New-InvalidOperationException -Message $errorMessage -ErrorRecord $_
            }
        }
        else
        {
            # Resource should not and does not exist

            Write-Verbose -Message ($script:localizedData.ResourceInDesiredState -f $Name)
        }
    }
} #end Set-TargetResource

Export-ModuleMember -Function *-TargetResource
