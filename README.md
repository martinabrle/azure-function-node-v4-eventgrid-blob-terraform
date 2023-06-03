To deploy the Azure infrastructure (function, storage, app service plan) into Azure, use the Terraform template in ```./terraform``` directory. Before you do that, you need to change CORS settings in ```main.tf``` and environment name, project namer and possibly also the location in ```terraform.tfvars``` (```[%PROJECT_NAME%]```, ```[%ENVIRONMENT_NAME%]``` placeholders, and the location ```"East US"``` is hardcoded). Then, log in into Azure from Azure CLI:
```
az login
```

change the current directory into ```./terraform```
```
cd terraform
```
and run Terraform deployment scripts:
```
terraform init
terraform plan
terraform apply
```

Then you need to get to the parent directory:
```
cd ..
```
and finally deploy the function:
```
func azure functionapp publish [%PROJECT_NAME%]-[%ENVIRONMENT_NAME%]-function-app
```

you can now test the function by pointing your browser to the following URL:
```
https://[%PROJECT_NAME%]-[%ENVIRONMENT_NAME%]-function-app.azurewebsites.net/api/HttpTrigger?code=[%ACCESS_KEY_COMES_HERE%]&name=Jonathan
```
or alternatively, using curl:
```
curl -i \
-d '{"key1":"value1", "key2":"value2"}' \
-H "Content-Type: application/json" \
-X POST "https://[%PROJECT_NAME%]-[%ENVIRONMENT_NAME%]-function-app.azurewebsites.net/api/HttpTrigger?code=[%ACCESS_KEY_COMES_HERE%]&Name=Jonathan"
```

This Azure function was created by following [this](https://learn.microsoft.com/en-us/azure/azure-functions/create-first-function-cli-node?pivots=nodejs-model-v3&tabs=azure-cli%2Cbrowser) tutorial.

Init the directory for Azure functions:
```
func init
```
and create the Azure function (here I used JavaScript and Node.JS v18)
```
func new
```
you can run this function locally using ```func start```, but you would first need to add a link to Azure Storage property in ```local.settings.json```

after trying this, you may want to investigate the Javascript v4(preview) programming model, as announced [here](https://techcommunity.microsoft.com/t5/apps-on-azure-blog/azure-functions-version-4-of-the-node-js-programming-model-is-in/ba-p/3773541)