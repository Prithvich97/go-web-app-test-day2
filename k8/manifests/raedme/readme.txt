#step -1 
aws configure 
aws sts get-caller-identity


#step-2 - create cluster 
 eksctl create cluster --name demo-cluster --region us-east-1
 kubectl get nodes


#step-3 apply the deployment , service and ingress resource 
    kubectl apply -f .\k8\manifests\deployment.yaml
    kubectl apply -f .\k8\manifests\service.yaml
    kubectl apply -f .\k8\manifests\ingress.yaml
    

#step-4
    kubectl get ing

    this gives output 

            PS C:\Users\prith\Downloads\go-web-apps\go-web-app> kubectl get ing
            NAME         CLASS   HOSTS              ADDRESS   PORTS   AGE
            go-web-app   ngix    go-web-app.local             80      16s

        the adress portion is empty as the clasytype in service.yaml is  type: ClusterIP, 
        we will change the type to NodePort , we wanna check if all the delpoyment and ingress and service.yaml are working fine or not, by checking and exposing on ect noes 

    after editing and saving service.yaml, we will have output like 

                PS C:\Users\prith\Downloads\go-web-apps\go-web-app> kubectl get svc
                    NAME         TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)        AGE
                    go-web-app   NodePort    10.100.114.122   <none>        80:32293/TCP   3m40s
                    kubernetes   ClusterIP   10.100.0.1       <none>        443/TCP        26m
                    so now we now its been exposed on port 3229 , we add to our ec2 security group 
            PS C:\Users\prith\Downloads\go-web-apps\go-web-app> kubectl get nodes -o wide
                NAME                             STATUS   ROLES    AGE   VERSION                INTERNAL-IP      EXTERNAL-IP      OS-IMAGE         KERNEL-VERSION                  CONTAINER-RUNTIME
                ip-192-168-18-250.ec2.internal   Ready    <none>   20m   v1.30.11-eks-473151a   192.168.18.250   44.201.176.229   Amazon Linux 2   5.10.238-231.953.amzn2.x86_64   containerd://1.7.27
                ip-192-168-53-246.ec2.internal   Ready    <none>   20m   v1.30.11-eks-473151a   192.168.53.246   54.81.69.117     Amazon Linux 2   5.10.238-231.953.amzn2.x86_64   containerd://1.7.27
            
            and using the external-ip:32293/courses , will see if the deployment was succesful ,  if website is reachable, if its we can continue , 
            dont forget to change type: ClusterIP

step -5

 kubectl apply -f .\ingress-controller.yaml

        now will check 
            kubectl get ing

            NAME         CLASS   HOSTS              ADDRESS                                                                         PORTS   AGE
            go-web-app   nginx   go-web-app.local   a37f4bbeeb76e463f96ae5117f90c2c1-1ad29beadc67c3f2.elb.us-east-1.amazonaws.com   80      47m

  the adress portion the load balncer 
  now we can acess the through load balances but we need to dns mapping 



#step-6 (dns mapping )
after installl k8, deployment, ingress , ingress controller 

# now we will map dns
ns lookup <adress from "kebectl get ing ">
will get 2 adress map any of it to you loacal sysyem /dns mappping 

for windows go to notepad as adminstartor 
Navigate to:

C:\Windows\System32\drivers\etc
in the file type dropdown (bottom right), select “All Files” instead of “Text Documents”.

Select hosts file and open it.

at the end of file add this line 
<adress from "kebectl get ing "> go-web-app.local


step-7
now we will use helm 

mkdir helm
cd helm
helm create go-web-app-chart

rm -rf charts  /for linux
rm -Recurse -Force charts  /for windows

cd templates
rm -Recurse -Force *    #remove everything from this folder 

cp ../../../k8/manifests/* .

notepad .\deployment.yaml  (will edit the image name  , image: prithvich97/go-web-app:{{ .value.image.tag}}), what does this meanis helm will ok for input from value.yaml file

#lets check all the resources 
kubectl get all

# now we gonna delete evrything and use helm to re create our deployment 
 delete deploy go-web-app
  delete svc go-web-app
   delete ing go-web-app

#now if we kubectl get all , everything is deleted except cluster , which qwe need, now we wlll go to helm folder
   cd ..
   cd ..


#step -8
# now we gonna do the samething we did til now using helm so that we can have our ci/cd pipeline 

helm install go-web-app  ./go-web-app-chart

kubectl get deployment 
kubectl get svc 
kubectl get ing 

#now if i wanna check image tage , which is pickung value from variable.yaml

kubectl edit deployment go-web-app

helm uninstall go-web-app
#we were just checking if everything is working, so now we unistall 


#step-9

now we will build CI, stage 1 will be creating , build and unit testing , step-2 will be static code analysis , stage-3  creatin of docker image and push it 
step-4 update helm with docker image crated, 
stage 5---CD, will use argo cd to pull helm chat onto the k8 cluster 


check out the ci.yaml file it has all  the steps and code, after that ci.yaml have been completed

mkdir  .github/workflows

cretae ci.yaml
git add .

git commit -m "updated version of go-lint, manual go lint instal all bugs fixed-1"

git push 


now check workflow on git hub , also undersatnd how ci.yaml is picking up thing from helm/go-web-chart/values.yaml



#step-10

exit helm directory and back to go-web-app directory

kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml


now need to expose argocd, so that we can use the interface 

kubectl patch svc argocd-server -n argocd -p '{\"spec\": {\"type\": \"LoadBalancer\"}}'

kubectl get svc argocd-server -n argocd

  will have output , copy the extrnal ip  and open in browser , or do kubectl get nodes -o wide , take adress: port (port from kubectl get svc argocd-server -n argocd )


  now this will open argo cd interface 
  user :admin 
  password : kubectl get secrets -n argocd->argocd-initial-admin-secret-> open this and get the pwrd 
  kubectl edit secret argocd-initial-admin-secret -n argocd

         the pswrd wil be encoded so run ,

         echo pswrd | base64 --deocde   --for linux
         [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String("pswrd"))  -- for windows
 sonow basically argocd is on the same cluster 
 in argo cd click on +new app, check video for the instruction 

 now iu can open go-web-app.local/courses, it is accesible 


 #step-11 
 now lets verify if ci/cd pipeline is working 
 update the static contect 