locals {
  federated_identity_credential_body = {
    name      = var.display_name
    issuer    = var.issuer
    audiences = var.audiences
    claimsMatchingExpression = {
      value           = var.claims_matching_expression_value
      languageVersion = 1
    }
  }
}

resource "null_resource" "flexible_federated_identity_credential" {
  triggers = {
    application_id = var.application_id
    display_name   = var.display_name
    body_json      = jsonencode(local.federated_identity_credential_body)
  }

  provisioner "local-exec" {
    when    = create
    command = <<EOT
      az rest --method post --url 'https://graph.microsoft.com/beta/applications/f6d9593e-f9f8-4d9d-a1e9-52c5772f20e6/federatedIdentityCredentials' --headers 'Content-Type=application/json' --body "{\"audiences\":[\"api://AzureADTokenExchange\"],\"claimsMatchingExpression\":{\"languageVersion\":1,\"value\":\"claims['sub'] matches 'repo:GuggenheimInvestmentsPOC/IT-IaC-Azure:*'\"},\"issuer\":\"https://token.actions.githubusercontent.com\",\"name\":\"pipelines-plan\"}"
      
      # RAN MANUALLY
      #az rest --method post --url 'https://graph.microsoft.com/beta/applications/f6d9593e-f9f8-4d9d-a1e9-52c5772f20e6/federatedIdentityCredentials' --headers 'Content-Type=application/json' --body "{'audiences':['api://AzureADTokenExchange'],'claimsMatchingExpression':{'languageVersion':1,'value':'claims[\'sub\'] matches \'repo:GuggenheimInvestmentsPOC/IT-IaC-Azure:*\''},'issuer':'https://token.actions.githubusercontent.com','name':'pipelines-plan'}"
    EOT
  }

  provisioner "local-exec" {
    when    = destroy
    command = <<EOT
      CREDENTIAL_ID=$(
        az rest --method get --url 'https://graph.microsoft.com/beta${self.triggers.application_id}/federatedIdentityCredentials' --query "value[?name=='${self.triggers.display_name}'].id" -o tsv
      )

      az rest --method delete --url "https://graph.microsoft.com/beta${self.triggers.application_id}/federatedIdentityCredentials/$CREDENTIAL_ID"
    EOT
  }
}
