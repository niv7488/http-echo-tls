# http-echo: solution notes

## 1. What was done

### Step 2: bugs found and fixed
| File | Problem | Fix |
|---|---|---|
| service.yaml | `protocol: UDP`. HTTP runs over TCP, so the ingress could not reach the pod | `TCP` |
| deployment.yaml | `args: -port` is a flag of hashicorp/http-echo. `ealen/echo-server` ignores it and listens on port 80, while the Service and probes use 5678 | set env `PORT` = `service.port` |
| deployment.yaml | `containerPort: 5678` hardcoded | uses `.Values.service.port` |
| deployment.yaml | liveness probe ran `/bin/bash` + `wget`, which are not in the image, so the container is killed in a restart loop | `httpGet /` probe, tuned readiness probe |
| values.yaml | `requests.cpu: "6"`, `memory: 1Mi`, with broken indentation. A pod needing 6 CPUs stays Pending | cpu 25m, memory 64Mi, memory limit 128Mi |
| hpa.yaml | `autoscaling/v2beta1` was removed in Kubernetes 1.25 | `autoscaling/v2` with `target.averageUtilization` |
| layout | `_helmignore` should be `.helmignore`; templates must live in `templates/` | restructured |

### Step 3: TLS
* Ingress terminates TLS on port 443 using secret `http-echo-tls`.
* `nginx.ingress.kubernetes.io/ssl-redirect: "true"` redirects HTTP to HTTPS.
* `templates/tls-secret.yaml` generates a self-signed certificate (Helm `genSelfSignedCert`) for the host. `lookup` reuses the existing secret on upgrades, so the certificate does not change on every deploy.
* For production, set `ingress.selfSignedTLS.enabled=false` and use cert-manager (add the `cert-manager.io/cluster-issuer` annotation) or a pre-created secret.

### Production hardening and efficiency
* 2 replicas plus a PodDisruptionBudget (`minAvailable: 1`)
* Runs as non-root, read-only root filesystem, all capabilities dropped, seccomp RuntimeDefault, no privilege escalation
* Small CPU and memory footprint, memory limit set, HPA available (`autoscaling.enabled=true`)
* Real health probes so traffic only reaches ready pods

## 2. How it works now

    curl https://http-echo.k8s-server.local
      -> /etc/hosts resolves the name to the cluster entry point
      -> ingress-nginx controller (port 443, TLS terminated with secret http-echo-tls)
      -> Service http-echo (ClusterIP, TCP 5678)
      -> echo-server pods (PORT=5678) -> JSON describing the request

## 3. macOS: install and run

### 3.1 Install the tools
```bash
# Homebrew (skip if already installed)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

brew install minikube kubectl helm
brew install --cask docker        # Docker Desktop, used as the minikube driver
open -a Docker                    # start Docker Desktop, wait until it says "running"
```
Check: `minikube version && kubectl version --client && helm version && docker info`

### 3.2 Option A: automated
```bash
cd http-echo
./setup.sh
```
On macOS with the Docker driver the script maps the hostname to 127.0.0.1 and tells you to start the tunnel. In a second terminal run `minikube tunnel` (it asks for your password and must stay open), then rerun `./setup.sh`.

### 3.3 Option B: manual
```bash
minikube start --driver=docker
minikube addons enable ingress
kubectl -n ingress-nginx rollout status deploy/ingress-nginx-controller

helm lint ./http-echo
helm install http-echo ./http-echo --dry-run=server      # validation only
helm install http-echo ./http-echo --wait
kubectl get pods,svc,ingress

echo "127.0.0.1 http-echo.k8s-server.local" | sudo tee -a /etc/hosts

# second terminal, keep it open:
minikube tunnel

# first terminal:
curl -i  http://http-echo.k8s-server.local/     # 308 redirect to https
curl -k  https://http-echo.k8s-server.local/    # JSON response
helm test http-echo
```
Open https://http-echo.k8s-server.local/ in a browser and accept the self-signed certificate warning.

### 3.4 Cleanup
```bash
helm uninstall http-echo
minikube delete
sudo sed -i '' '/http-echo.k8s-server.local/d' /etc/hosts
```

## 4. Troubleshooting
* Pods Pending: `kubectl describe pod <pod>` and check the resource requests
* Pod CrashLoopBackOff: `kubectl logs <pod>`. If the cause is the read-only filesystem or the user ID, relax `securityContext` / `podSecurityContext` in values.yaml
* Ingress has no address or curl hangs: make sure `minikube tunnel` is running and /etc/hosts points to 127.0.0.1
* Install fails with an admission webhook error: wait a few seconds for ingress-nginx to finish starting and retry
* Port 80/443 already in use on the Mac: stop the local service that uses them, then restart the tunnel



<img width="1358" height="1273" alt="image" src="https://github.com/user-attachments/assets/34c0b1b5-1021-4cd2-ad58-24ee3289172e" />

