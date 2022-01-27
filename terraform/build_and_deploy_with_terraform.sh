#Build the gcp files
echo "Building files"
npm run build-terraform

echo "Initializing terraform providers"
terraform init

#Destroy current structure
echo "Destroy current structure"
terraform destroy

#Apply plan
echo "Applying terraform"
terraform apply


echo "Deploy finished, access https://storage.googleapis.com/ipla-1652-terraform-app/index.html to confirm"
