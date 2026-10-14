# DevOps Task Home Assignment #


## Summary  ##
Here is a description of our home assignment for a Senior DevOps position.
The task includes several steps: In the first step, you will need to set up 
a local Kubernetes Cluster together with an ingress controller.
Next, you will need to install the http-echo helm chart package 
and fix the environment (troubleshooting). 
The last step is to add https support.

### Step 1: Installation and deployment  ###
Here you need to set up a local Kubernetes cluster using minikube (or any other tool)
and install the ingress controller and helm. Finally, you will need to deploy a simple
http-echo helm chart package


* Create local Kubernetes Cluster (you can use [minikube](https://minikube.sigs.k8s.io/docs/start/) / [MicroK8s](https://microk8s.io/docs) / etc.)
* Install [Helm](https://helm.sh/docs/intro/install/)
* Deploy http-echo helm chart package

### Step 2:  Fix Environment  ###
The Helm package is **broken** you need to investigate what went wrong
and fix the environment. Below you can see instructions on how to check
if the environment is up and running.

* how to make sure the deployment is fully working:
    * All the pods and services are up and running without any errors
    * The echo server is up and running:
        * Add to /etc/hosts the following mapping: 127.0.0.1 http-echo.k8s-server.local(In case of Minikube add ```minikube ip``` instead of 127.0.0.1)
        * Open browser at http://http-echo.k8s-server.local/ or curl to the url. You should get a json response that describe the request:
    ```
    {"host":{"hostname":"http-echo.k8s-server.local","ip":"::ffff:10.1.0.14","ips":[]},"http":
  {"method":"GET","baseUrl":"","originalUrl":"/","protocol":"http"},"request":{"params":
  {"0":"/"},"query":{},"cookies":{},"body":{},"headers":{"host":"http-echo.k8s-server.local"
  ,"x-request-id":"cc0fb6714354cf630bcc345cd0008c56","x-real-ip":"192.168.65.3",
  "x-forwarded-for":"192.168.65.3","x-forwarded-host":"http-echo.k8s-server.local",
  "x-forwarded-port":"80","x-forwarded-proto":"http","x-forwarded-scheme":"http",
  "x-scheme":"http","upgrade-insecure-requests":"1","user-agent":"Mozilla/5.0 (Macintosh;Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/97.0.4692.71 Safari/537.36","accept":"text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,/;q=0.8,application/signed-exchange;v=b3;q=0.9","accept-encoding":"gzip, deflate","accept-language":"en-US,en;q=0.9","apikey":"JdazXPS4F4rySrosZU/uzfnDu2vBUlyu0zJMgkC6LEQ="}},"environment":{"PATH":"/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin","HOSTNAME":"http-echo-69f585ff95-srk6l","HTTP_ECHO_SERVICE_HOST":"10.102.9.43","HTTP_ECHO_PORT":"tcp://10.102.9.43:5678","HTTP_ECHO_PORT_5678_TCP_PROTO":"tcp","KUBERNETES_PORT_443_TCP_PORT":"443","HTTP_ECHO_PORT_5678_TCP":"tcp://10.102.9.43:5678","HTTP_ECHO_PORT_5678_TCP_PORT":"5678","HTTP_ECHO_PORT_5678_TCP_ADDR":"10.102.9.43","KUBERNETES_SERVICE_PORT_HTTPS":"443","KUBERNETES_PORT":"tcp://10.96.0.1:443","KUBERNETES_PORT_443_TCP_ADDR":"10.96.0.1","HTTP_ECHO_SERVICE_PORT":"5678","HTTP_ECHO_SERVICE_PORT_HTTP":"5678","KUBERNETES_SERVICE_HOST":"10.96.0.1","KUBERNETES_SERVICE_PORT":"443","KUBERNETES_PORT_443_TCP":"tcp://10.96.0.1:443","KUBERNETES_PORT_443_TCP_PROTO":"tcp","NODE_VERSION":"12.19.0","YARN_VERSION":"1.22.5","HOME":"/root"}}
    ```


### Step 3:  (Bonus) Add feature  ###

Please add TLS  support to nginx ingress bind to port 443

#### how to make sure the TLS is fully working?  ####
Do the same test from previous step with https (https://http-echo.k8s-server.local/)

### Guidelines and Preuest Information ###

* Please treat your solution as a task that need to be deployed in production, so we expect to a high level of maturity of the solution 
* Pay attention to the performance of the solution you use and make sure it runs efficiently with minimal overhead as possible. 
* The task should take about 2-4 hours. 
* Please read the instructions carefully. 
* If there is anything incomprehensible - please contact us for clarifications.

### Submission ###
* Please provide a working solution, **submitted as a new git local branch**, and in the comment please provide a short description which explains any important issue or comments about your work 


