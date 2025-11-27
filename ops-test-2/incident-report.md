# Incident Report

**Date:** 27-11-2025  
**Severity:** High  
**Status:** Resolved  

---


## Summary
On November 27, 2025, the `advanced-app` deployment on the `test2` namespace of our Minikube cluster experienced startup failures and container image issues. The primary issue was the failure of the sidecar container to pull its image and misconfiguration of shared log volumes between the main application container and the sidecar.

## Impact
- Main Go application pods were unstable, resulting in partial service unavailability.
- Sidecar container failures prevented log access and proxy reliability.
- Horizontal Pod Autoscaler (HPA) did not scale pods as expected under load.
- Network proxy caused intermittent 504 gateway errors.
- Build failures and image misconfigurations delayed deployments.
- The `advanced-app` pods were not fully ready, causing partial service unavailability.
- Logs from the main application were not visible via the sidecar container for several hours.
- Continuous deployment and scaling of the service were impacted until the issue was resolved.


## Root Cause
### 1. Go Application Bugs
- **Memory leak**: The app was appending to a global slice for every request.
- **Race condition**: Incrementing a global counter without atomic operations or mutex.
- **Latency**: Artificial 2-second sleeps in request handling.
- **Faulty health endpoint**: Random failures caused by even Unix timestamps.

**Fixes**:
- Replaced counter increment with `atomic.AddInt64`.
- Removed artificial sleeps.
- Removed memory leak slice.
- Health endpoint now reliably returns 200 OK.
- Added logging to `/var/log/test2/app.log`.

### 2. Dockerfile Issues
- Missing CA certificates.
- Binary copy path incorrect in multi-stage build.
- Exposed wrong port.
- No non-root user.
- Inefficient layer structure.

**Fixes**:
- Installed `ca-certificates`.
- Corrected binary copy from build stage to final stage.
- Set correct `EXPOSE 8080`.
- Added non-root user and switched to it.
- Reordered RUN and COPY instructions for better layer caching.

### 3. Kubernetes Deployment
- Readiness probe misconfigured.
- Resource limits too low.
- Wrong `imagePullPolicy`.
- Sidecar container conflicts.
- Ports misconfigured.

**Fixes**:
- Corrected `readinessProbe` path and port.
- Set CPU/memory requests and limits properly.
- Changed `imagePullPolicy` to `IfNotPresent`.
- Replaced missing sidecar image with `busybox` tailing logs.
- Verified both containers run and share logs via `emptyDir`.

### 4. HPA Issues
- **HPA showing `<unknown>` for CPU targets**: Metrics were unavailable with error "failed to get cpu utilization: missing request for cpu in container sidecar"
- **Autoscaling completely non-functional**: HPA could not compute replica count without resource requests
- **Sidecar container missing resource requests**: Without CPU requests defined on all containers, HPA cannot calculate utilization percentage

**Root Cause Analysis**:
The HPA calculates CPU utilization as: `(current usage / requested CPU) × 100%`

Without CPU resource requests defined on **all containers** (including sidecar), the HPA cannot compute utilization and shows `<unknown>`, preventing any autoscaling from occurring.

**Fixes**:
- Added CPU and memory resource requests/limits to sidecar container:
  - Requests: CPU 50m, Memory 64Mi
  - Limits: CPU 100m, Memory 128Mi
- Verified main container already had proper resource definitions
- Confirmed HPA configuration was correct with `averageUtilization: 70%`
- Validated metrics server was running and functional

**Validation**:
- Before fix: HPA showed `cpu: <unknown>/70%`, fixed at 3 replicas
- After fix: HPA showed `cpu: 1%/70%` with functional metrics
- Load test: Successfully scaled from 1 → 3 → 5 replicas under CPU load
- Scale-down: Automatically returned to 1 replica after 5-minute cooldown
- Monitoring: Used `kubectl get hpa --watch`, `kubectl top pods`, and `kubectl describe hpa` to verify behavior

### 5. Sidecar Proxy & Network Issues

1. **Container image issues**:
   - The main application container `advanced-candidate:latest` was successfully built and loaded into Minikube.
   - The sidecar container `advanced-sidecar:latest` did not exist locally and failed to pull from a remote repository, causing `ImagePullBackOff`.
2. **Log volume misconfiguration**:
   - Initially, `hostPath` volume pointed to a directory that did not exist or was misconfigured, causing `MountVolume.SetUp failed`.
3. **Application log setup**:
   - The Go application did not write logs to the expected shared directory, preventing the sidecar from tailing logs.

## Timeline
| Time (approx.) | Event |
|----------------|-------|
| 21:13          | Pods scheduled in Minikube cluster. |
| 21:14          | `advanced-app` main container started; sidecar failed to pull image. |
| 21:15          | Attempted deployment with `hostPath` log volume; mount failed. |
| 21:20          | Reconfigured deployment to use `emptyDir` volume. |
| 21:25          | Updated Go application to write logs to `/var/log/test2/app.log`. |
| 21:30          | Rebuilt Docker image `advanced-candidate:latest` and loaded into Minikube. |
| 21:35          | All pods running; sidecar successfully tailing logs. |
| 22:45          | HPA issue identified: showing `<unknown>` CPU metrics. |
| 22:50          | Root cause identified: sidecar container missing resource requests. |
| 23:00          | Added resource requests/limits to sidecar container. |
| 23:05          | HPA metrics available: showing `cpu: 1%/70%`. |
| 23:10          | Load test initiated with `yes` command to generate CPU load. |
| 23:12          | HPA successfully scaled deployment from 1 to 3 replicas at 67% CPU. |
| 23:15          | Load test stopped; monitoring scale-down behavior. |
| 23:20          | HPA scaled back to 1 replica after 5-minute stabilization window. |

## Fixes Applied
1. **Sidecar image issue**:
   - Replaced the missing sidecar image `advanced-sidecar:latest` with `busybox` for log tailing.
2. **Volume configuration**:
   - Replaced `hostPath` with `emptyDir` volume for ephemeral log sharing between containers.
3. **Application logging**:
   - Updated Go application to write logs to `/var/log/test2/app.log`.
   - Ensured `log.SetOutput()` was configured to write to the shared volume.
4. **Deployment adjustments**:
   - Updated Kubernetes Deployment YAML with proper `volumeMounts` and `volumes` configuration for both containers.
5. **Image load**:
   - Built `advanced-candidate:latest` and loaded it into Minikube using `minikube image load`.
6. **HPA resource configuration**:
   - Added resource requests and limits to sidecar container in deployment manifest.
   - Validated both main and sidecar containers have CPU/memory requests defined.
   - Confirmed metrics server functionality using `kubectl top pods`.
7. **HPA testing and validation**:
   - Generated CPU load using `yes > /dev/null &` commands.
   - Monitored scaling behavior with `kubectl get hpa --watch`.
   - Verified automatic scale-up and scale-down functionality.

## Preventive Actions
- Always verify that all referenced container images exist locally or in a reachable registry before deploying.
- Use `emptyDir` or PVC volumes for ephemeral log sharing instead of host-dependent paths.
- Implement standard logging conventions in applications to ensure logs are accessible to sidecars or log aggregators.
- **Enforce resource requests/limits on all containers**: Add admission controller or policy to require resource definitions on every container in a pod.
- **Validate HPA prerequisites before deployment**: Ensure metrics server is running and all containers have resource requests defined.
- **Standardize deployment templates**: Create deployment templates that include resource requests/limits by default for all container types.
- **Document container resource guidelines**: Establish minimum resource request standards for different container types (main app, sidecar, init containers).

## Monitoring / Alerting Improvements
- Add a readiness probe check for sidecar containers to alert if they fail to start.
- Implement alerts for `ImagePullBackOff` or `ErrImagePull` events in Kubernetes.
- Monitor log volume mounts to ensure logging pipelines are operational.
- Use CI/CD validation to verify that all images exist in the target environment before applying deployments.
- **HPA scaling alerts**: Alert on CPU thresholds and when HPA fails to scale.
- **HPA metrics alerts**: Alert when HPA shows `<unknown>` targets or `FailedGetResourceMetric` errors.
- **Resource request validation**: Add pre-deployment checks to ensure all containers have resource requests defined.
- **Autoscaling dashboard**: Create monitoring dashboard showing HPA status, current/desired replicas, CPU utilization trends, and scaling events.
- **Load testing automation**: Implement regular automated load tests to validate HPA functionality in non-production environments.

## Key Learnings
1. **All containers need resource requests for HPA**: HPA requires CPU requests on every container in a pod, not just the main application container.
2. **Metrics server is critical**: Ensure `kubectl top pods` works before expecting HPA to function.
3. **Scaling has time delays**: Scale-up takes 30-60 seconds, scale-down takes 5+ minutes (default stabilization window).
4. **Monitor with multiple tools**: Use `kubectl get hpa --watch`, `kubectl top pods`, and `kubectl describe hpa` together for complete visibility.
5. **Test autoscaling regularly**: Include HPA testing in deployment validation to catch issues early.