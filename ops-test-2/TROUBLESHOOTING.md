# TROUBLESHOOTING.md

## Fix the Go Application

### Memory Leak
**Issue:** A global slice kept growing on every request, causing unbounded memory usage.  
**Fix:** Removed the slice and all append operations.

### Race Condition
**Issue:** `counter` was modified concurrently without synchronization.  
**Fix:** Replaced with `atomic.AddInt64` and removed the mutex.

### Latency
**Issue:** `time.Sleep(2s)` caused unnecessary delays on every request.  
**Fix:** Removed the time sleep.

### Faulty Health Check
**Issue:** `/healthz` randomly returned 500 based on timestamp.  
**Fix:** Health endpoint now always returns `200 OK`.

### Missing Logging
**Issue:** No request-level logs for tracing behavior.  
**Fix:** Added logging for each handled request, including path and counter value.
**Implementation:**
```go
f, err := os.OpenFile("/var/log/test2/app.log", os.O_APPEND|os.O_CREATE|os.O_WRONLY, 0644)
if err != nil {
    log.Fatal(err)
}
log.SetOutput(f)
log.Println("App started")
```

---

## Fix the Broken Multi-Stage Dockerfile

### Issues Identified
- Missing CA certificates (caused HTTPS failures during module download and runtime)
- Wrong binary copy path
- Wrong exposed port (app listens on 8080, not 80)
- Running container as root
- Inefficient layer structure (no caching for go.mod/go.sum)

### Fixes Applied
- Added CA certificates in builder and runtime images  
- Copied `go.mod` + `go.sum` first for proper caching  
- Corrected binary build and copy paths  
- Exposed correct port `8080`  
- Added non-root `appuser`  
- Simplified clean multi-stage build  

### Final Optimized Dockerfile
```dockerfile
FROM golang:1.22 AS builder

RUN apk add --no-cache ca-certificates

WORKDIR /build

COPY app/go.mod app/go.sum ./
RUN go mod download

COPY app/ .
RUN CGO_ENABLED=0 GOOS=linux go build -o server .

FROM alpine:3.19

RUN apk add --no-cache ca-certificates
RUN adduser -D -g '' appuser

WORKDIR /app

COPY --from=builder /build/server /app/server

EXPOSE 8080
USER appuser

ENTRYPOINT ["/bin/server"]
```

---

## Fix the Kubernetes Deployment

### Issues Identified
- Readiness probe misconfigured (wrong path/port)
- Resource limits too low (CPU/memory)
- Wrong imagePullPolicy
- Sidecar image conflicts
- Shared logs not mounted properly

### Fixes Applied
- Corrected `readinessProbe` to `/healthz` on port 8080
- Set `resources.requests` and `resources.limits` appropriately
- Set `imagePullPolicy: IfNotPresent`
- Replaced missing sidecar image with `busybox` tailing logs
- Used `emptyDir` volume to share logs between containers

### Deployment Example
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: advanced-app
spec:
  replicas: 3
  selector:
    matchLabels:
      app: advanced-app
      component: sidecar
  template:
    metadata:
      labels:
        app: advanced-app
        component: sidecar
    spec:
      containers:
      - name: advanced-app
        image: advanced-candidate:latest
        imagePullPolicy: IfNotPresent
        ports:
        - containerPort: 8080
        readinessProbe:
          httpGet:
            path: /healthz
            port: 8080
          initialDelaySeconds: 2
          periodSeconds: 3
        resources:
          requests:
            cpu: "100m"
            memory: "128Mi"
          limits:
            cpu: "300m"
            memory: "256Mi"
        volumeMounts:
        - name: logs
          mountPath: /var/log/test2
      - name: sidecar
        image: busybox
        command: ["sh", "-c", "tail -F /var/log/test2/*.log"]
        volumeMounts:
        - name: logs
          mountPath: /var/log/test2
      volumes:
      - name: logs
        emptyDir: {}
```

---

## Fix the HPA (HorizontalPodAutoscaler)

### Issues Identified
- HPA showing `<unknown>` for CPU targets
- Metrics unavailable: "failed to get cpu utilization: missing request for cpu in container sidecar"
- Autoscaling completely non-functional
- Sidecar container had no resource requests defined

### Root Cause
The HPA calculates CPU utilization as a percentage: `(current usage / requested CPU) × 100%`

Without CPU resource requests defined on **all containers** (including sidecar), the HPA cannot compute utilization and shows `<unknown>`, preventing any autoscaling from occurring.

### Fixes Applied

1. **Added CPU resource requests to sidecar container:**
```yaml
- name: sidecar
  image: busybox
  command: ["sh", "-c", "tail -F /var/log/test2/*.log"]
  resources:
    requests:
      cpu: "50m"        # Added
      memory: "64Mi"    # Added
    limits:
      cpu: "100m"       # Added
      memory: "128Mi"   # Added
```

2. **Verified main container already had resources defined:**
```yaml
- name: advanced-app
  resources:
    requests:
      cpu: "100m"
      memory: "128Mi"
    limits:
      cpu: "300m"
      memory: "256Mi"
```

3. **Confirmed HPA configuration was correct:**
```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: advanced-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: advanced-app
  minReplicas: 1
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
```

### Validation Process

1. **Verified resource requests were applied:**
```bash
kubectl describe deployment advanced-app -n test2 | grep -A 10 "Requests"
```

2. **Confirmed HPA metrics became available:**
```bash
kubectl get hpa advanced-hpa -n test2
# Before: cpu: <unknown>/70%
# After:  cpu: 1%/70%
```

3. **Generated CPU load to test autoscaling:**
```bash
POD_NAME=$(kubectl get pods -n test2 -l app=advanced-app -o jsonpath='{.items[0].metadata.name}')

# generate sustained CPU load
kubectl exec -n test2 $POD_NAME -c advanced-app -- sh -c "
yes > /dev/null &
yes > /dev/null &
yes > /dev/null &
yes > /dev/null &
"
```

4. **Monitored scaling behavior:**
```bash
# watch HPA in real-time
kubectl get hpa advanced-hpa -n test2 --watch

# watch pod count
kubectl get pods -n test2 -l app=advanced-app --watch

# check CPU utilization
kubectl top pods -n test2 -l app=advanced-app
```

### Results

**Before fix:**
- HPA Status: `cpu: <unknown>/70%`
- Replicas: Fixed at 3 (no autoscaling)
- Error: "FailedGetResourceMetric"

**After fix:**
- HPA Status: `cpu: 1%/70%` (metrics working)
- Replicas: Dynamic (1 → 3 → 5 based on load)
- Scaling events visible in `kubectl describe hpa`

**Load test results:**
- Initial state: 1 replica at ~1% CPU
- Under load: Scaled to 3 replicas at ~67% CPU
- Peak load: Scaled to 5+ replicas maintaining <70% CPU per pod
- After load stopped: Scaled back to 1 replica (5-minute cooldown)

### Key Learnings

1. **All containers need resource requests** - HPA requires CPU requests on every container in a pod, not just the main application container
2. **Metrics server is required** - Ensure `kubectl top pods` works before expecting HPA to function
3. **Scaling takes time** - Scale-up: 30-60 seconds, Scale-down: 5+ minutes (default stabilization window)
4. **Monitor with multiple tools** - Use `kubectl get hpa --watch`, `kubectl top pods` and `kubectl describe hpa` together

### Monitoring Commands
```bash

kubectl get hpa -n test2

kubectl describe hpa advanced-hpa -n test2

kubectl top pods -n test2 -l app=advanced-app

kubectl exec -n test2 $POD_NAME -c advanced-app -- pkill yes
kubectl exec -n test2 $POD_NAME -c advanced-app -- pkill -f "while true"
```

---

## Fix the Network Issues (Sidecar Debugging)

### Issues Identified
- Sidecar proxy introduced 3s artificial delays
- Randomly dropped 20% of requests
- Caused 504 gateway errors in main app

### Fixes Applied
- Removed sleep and random failure logic from sidecar
- Simplified sidecar to `tail -F` logs only
- Verified with repeated requests; zero 504s observed
- Logs accessible via shared `emptyDir` volume

---

## Log Analysis
- Added logging for Go application in `/var/log/test2/app.log`
- Sidecar container now tails logs for debugging
- Verified that logs are written and visible in both containers

---

## Production-Style Incident Report
Refer to `incident-report.md` for the full summary including impact, timeline, root causes, fixes, preventive actions, and monitoring improvements.
