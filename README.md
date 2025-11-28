# Troubleshooting Submission

**Name:** Tanjibul Hasan Rafi  
**Email:** rafitanjibulhasan@gmail.com  
**Time Taken:** 5 hours  
**Environment:** Minikube  

## Assumptions
- Cluster resources are limited due to Minikube's default configuration.
- Host directories are not automatically mounted into pods; therefore, a local `logs/` folder cannot be used directly inside Minikube.
- Sidecar containers may fail to start without explicit CPU and memory requests.
- Both the main application and the sidecar container run on the same pod/node, so resource contention can directly affect application performance and readiness.
- NetworkPolicy is too restrictive (e.g., only allows pods with component=sidecar), Istio proxies from other pods may be blocked unless their labels match.
