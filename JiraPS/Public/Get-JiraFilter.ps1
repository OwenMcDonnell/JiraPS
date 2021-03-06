﻿function Get-JiraFilter {
    [CmdletBinding(DefaultParameterSetName = 'ByFilterID')]
    param(
        [Parameter( Position = 0, Mandatory, ParameterSetName = 'ByFilterID' )]
        [String[]]
        $Id,
        <#
          #ToDo:CustomClass
          Once we have custom classes for the module,
          this can use ValueFromPipelineByPropertyName
          and we will no longer need the InputObject
        #>

        [Parameter( Mandatory, ValueFromPipeline, ParameterSetName = 'ByInputObject' )]
        [ValidateNotNullOrEmpty()]
        [ValidateScript(
            {
                if (("JiraPS.Filter" -notin $_.PSObject.TypeNames) -and (($_ -isnot [String]))) {
                    $errorItem = [System.Management.Automation.ErrorRecord]::new(
                        ([System.ArgumentException]"Invalid Type for Parameter"),
                        'ParameterType.NotJiraFilter',
                        [System.Management.Automation.ErrorCategory]::InvalidArgument,
                        $_
                    )
                    $errorItem.ErrorDetails = "Wrong object type provided for Filter. Expected [JiraPS.Filter] or [String], but was $($_.GetType().Name)"
                    $PSCmdlet.ThrowTerminatingError($errorItem)
                    <#
                      #ToDo:CustomClass
                      Once we have custom classes, this check can be done with Type declaration
                    #>
                }
                else {
                    return $true
                }
            }
        )]
        [Object[]]
        $InputObject,

        [PSCredential]
        $Credential
    )

    begin {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"

        $server = Get-JiraConfigServer -ErrorAction Stop

        $resourceURi = "$server/rest/api/latest/filter/{0}"
    }

    process {
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] ParameterSetName: $($PsCmdlet.ParameterSetName)"
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] PSBoundParameters: $($PSBoundParameters | Out-String)"

        switch ($PSCmdlet.ParameterSetName) {
            "ByFilterID" {
                foreach ($_id in $Id) {
                    Write-Verbose "[$($MyInvocation.MyCommand.Name)] Processing [$_id]"
                    Write-Debug "[$($MyInvocation.MyCommand.Name)] Processing `$_id [$_id]"

                    $parameter = @{
                        URI        = $resourceURi -f $_id
                        Method     = "GET"
                        Credential = $Credential
                    }
                    Write-Debug "[$($MyInvocation.MyCommand.Name)] Invoking JiraMethod with `$parameter"
                    $result = Invoke-JiraMethod @parameter

                    Write-Output (ConvertTo-JiraFilter -InputObject $result)
                }
            }
            "ByInputObject" {
                foreach ($object in $InputObject) {
                    Write-Verbose "[$($MyInvocation.MyCommand.Name)] Processing [$object]"
                    Write-Debug "[$($MyInvocation.MyCommand.Name)] Processing `$object [$object]"

                    if ((Get-Member -InputObject $object).TypeName -eq 'JiraPS.Filter') {
                        $thisId = $object.ID
                    }
                    else {
                        $thisId = $object.ToString()
                        Write-Verbose "[$($MyInvocation.MyCommand.Name)] ID is assumed to be [$thisId] via ToString()"
                    }

                    Write-Output (Get-JiraFilter -Id $thisId -Credential $Credential)
                }
            }
        }
    }

    end {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Complete"
    }
}
