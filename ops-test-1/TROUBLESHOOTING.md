# SRE Assessment - Troubleshooting Documentation

## Fix the Application
- **Issue 1: Slow Home Endpoint**
    - **Problem:** The `/` endpoint was taking 3-8 seconds to respond.
    - **Root Cause:** There was a deliberate `time.sleep(random.randint(3,8))` slowing down every request.
    - **Fix:** Removed the `time.sleep()` call. The endpoint now responds instantly.

- **Issue 2: Health Check Returning Error Status**
    - **Problem:** The `/healthz` endpoint was returning HTTP 500 even though the service was healthy.
    - **Root Cause:** The endpoint was explicitly returning 500.
    - **Fix:** Changed the status code to 200 to correctly indicate a healthy service.

---

## Fix the Dockerfile
- **Issue 1: Incorrect WORKDIR and COPY Path**
    - **Problem:** Dockerfile had `WORKDIR /src` and `COPY app .`, creating a confusing directory structure.
    - **Fix:** Set `WORKDIR /app` and copy files accordingly:
      ```dockerfile
      WORKDIR /app
      COPY app/requirements.txt .
      RUN pip install --no-cache-dir -r requirements.txt
      COPY app/ .
      ```

- **Issue 2: Wrong Port Exposed**
    - **Problem:** Dockerfile exposed port 80, but app ran on 5000.
    - **Fix:** Updated exposed port:
      ```dockerfile
      EXPOSE 8080
      ```

- **Issue 3: Inefficient Layer Caching**
    - **Problem:** Copying all files before `pip install` invalidates cache unnecessarily.
    - **Fix:** Copy `requirements.txt` first, install dependencies, then copy rest of code (see above).

---

## Fix the Kubernetes Deployment
- **Issue 1: Container Port Mismatch**

    - **Problem:** Flask app runs on port 8080, but containerPort was 80.

    - **Fix:** Updated containerPort in the Deployment to 8080 to match the app.


- **Issue 2: Readiness Probe Failing**

    - **Problem:** Probe was hitting /healthz on wrong port and returning 500.

    - **Fix:** Updated readinessProbe to hit /healthz on port 8080 and return 200.

    - **Result:** Kubernetes only routes traffic to pods that are actually ready.


- **Issue 3: Service Not Routing Properly**

    - **Problem:** Service targetPort did not match container port. Selector labels must match Deployment.

    - **Fix:**

        targetPort: 8080 to match container port.

        Verified selector matches app: sre label in Deployment.

```
Bonus Improvements:

Added livenessProbe to automatically restart pods if they become unresponsive.

Added resource requests and limits to ensure proper scheduling and prevent pods from overusing node resources.
```
```
Notes on Probes:

Readiness Probe: Checks if the pod is ready to accept traffic. Pods failing this are temporarily removed from service endpoints.

Liveness Probe: Checks if the pod is alive. Pods failing this are restarted by Kubernetes.
```
---

## Debug logs.txt
- **Readiness probe failures:** Caused by `/healthz` returning HTTP 500 instead of 200. Kubernetes considered pod unready.
- **Slow service:** Original `time.sleep` in `/` endpoint caused artificial delay.
- **Root cause:** Combination of blocking code in app and misconfigured health endpoint.
- **Permanent fix:** Remove blocking code, fix `/healthz` endpoint, and ensure Docker/K8s probes are correct.

---

## Commands Used During Debugging
```bash
# Install required packages
pip install -r requirements.txt

# Run app locally
python3 app/main.py

# Build and run Docker
docker build -t sre-candidate:latest .
docker run -p 8080:8080 sre-test-app

# Start Minikube
minikube start

# Load docker image into Minikube
minikube image load sre-candidate:latest


# Apply Kubernetes deployment
kubectl apply -f k8s/deployment.yaml
kubectl apply -f k8s/service.yaml

# Delete pods
kubectl delete pod -l app=sre

# Check pod logs and status
kubectl get pods
kubectl get svc
kubectl logs <pod-name>
kubectl describe pod <pod-name>
