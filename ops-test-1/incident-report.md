# Incident Report: SRE Assessment Service Outage

**Date:** 25-11-2025  
**Severity:** High  
**Status:** Resolved  

---

## Summary

The SRE assessment service experienced complete unavailability due to multiple application and configuration issues. All pods failed readiness probes, preventing traffic from reaching the service. The issues stemmed from intentionally broken code including artificial delays, incorrect HTTP status codes and mismatched port configurations.

---

## Impact

**Duration:** Approximately 1 hours from deployment to resolution

**Affected Systems:**
- 100% service unavailability
- All pods in failed/unready state
- No traffic could reach the application

**User Impact:**
- All HTTP requests failed or timed out
- Health check endpoints returning errors
- Service completely non-functional

---

## Root Cause

Three primary issues caused the outage:

1. **Health Endpoint Returning HTTP 500**
   - `/healthz` explicitly returned status code 500 instead of 200
   - Kubernetes readiness probes failed, marking all pods as unready
   - Pods were never added to service endpoints

2. **Artificial Delay in Application Code**
   - `time.sleep(random.randint(3,8))` caused 3-8 second delays on every request
   - Made the service appear unresponsive
   - Caused legitimate requests to timeout

3. **Port Configuration Mismatch**
   - Application ran on port 8080
   - Dockerfile exposed port 80
   - Kubernetes probes initially targeted wrong port
   - Created confusion in service routing

---

## What Was Fixed

### Application Layer (app/main.py)
```python
# Fixed health endpoint status code
return jsonify({"status": "ok"}), 200  # Changed from 500

# Removed artificial delay
# time.sleep(random.randint(3,8))  # Commented out
```

### Container Layer (Dockerfile)
```dockerfile
# Fixed port exposure
EXPOSE 8080  # Changed from 80

COPY app/requirements.txt .

RUN pip install --no-cache-dir -r requirements.txt
COPY app/ .
```

### Kubernetes Layer (deployment.yaml)
```yaml
# Tell Minikube to use local images
imagePullPolicy: IfNotPresent
# Fixed container port
containerPort: 8080

# Fixed readiness probe
readinessProbe:
  httpGet:
    path: /healthz
    port: 8080
  initialDelaySeconds: 5
  periodSeconds: 5

# Added liveness probe
livenessProbe:
  httpGet:
    path: /healthz
    port: 8080
  initialDelaySeconds: 10
  periodSeconds: 10

# Added resource limits
resources:
  requests:
    memory: "128Mi"
    cpu: "100m"
  limits:
    memory: "256Mi"
    cpu: "200m"
```

### Service Layer (service.yaml)
```yaml
# Fixed target port
targetPort: 8080  # Matches container port
```

---

## Preventive Actions

### Immediate (Implemented)
- ✅ Removed all blocking operations from request handlers
- ✅ Ensured health endpoints return proper HTTP status codes
- ✅ Aligned port configurations across all layers
- ✅ Added both readiness and liveness probes
- ✅ Implemented resource requests and limits

### Short-term (Recommended)
- [ ] Add pre-deployment smoke tests
- [ ] Implement automated health check validation
- [ ] Add monitoring and alerting for probe failures
- [ ] Create deployment checklist

### Long-term (Recommended)
- [ ] Implement CI/CD pipeline with automated testing
- [ ] Add integration tests in staging environment
- [ ] Set up Prometheus metrics and Grafana dashboards
- [ ] Implement canary deployments for safer rollouts
- [ ] Create runbooks for common failure scenarios
- [ ] Schedule regular disaster recovery drills

---

## Lessons Learned

**What Went Well:**
- Issues were quickly identified through systematic log analysis
- All problems were resolved in a single deployment cycle
- Documentation was thorough throughout the process

**What Could Be Improved:**
- Pre-deployment testing would have caught all issues
- Automated validation could prevent similar problems
- Better initial configuration management needed

**Action Items:**
- Develop automated pre-deployment validation scripts
- Create Kubernetes manifest validation pipeline
- Establish SRE team best practices documentation

---

## Sign-off

**Prepared by:** Tanjibul Hasan Rafi  
**Date:** 25-11-2025    

---

*This report follows a blameless post-mortem approach, focusing on systemic improvements rather than individual errors.*