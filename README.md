# Troubleshooting Submission

**Name:** Tanjibul Hasan Rafi  
**Email:** rafitanjibulhasan@gmail.com  
**Time Taken:** 7 hours  
**Environment:** Minikube  

## Assumptions
- Cluster resources are limited due to Minikube's default configuration.
- Host directories are not automatically mounted into pods; therefore, a local `logs/` folder cannot 
be used directly inside Minikube.
- Sidecar containers may fail to start without explicit CPU and memory requests.
- Both the main application and the sidecar container run on the same pod/node, so resource contention can directly affect application performance and readiness.
- NetworkPolicy is too restrictive (e.g., only allows pods with component=sidecar), Istio proxies from other pods may be blocked unless their labels match.

## Screenshots

<img width="3746" height="876" alt="Screenshot from 2025-11-27 23-14-58" src="https://github.com/user-attachments/assets/538d3fc3-7aac-4ecb-ab68-8296efb54266" />

<img width="3216" height="1428" alt="Screenshot from 2025-11-27 23-04-14" src="https://github.com/user-attachments/assets/11fa5022-0d55-4b75-81fd-5b51c8f4c3ca" />

<img width="1252" height="764" alt="Screenshot from 2025-11-27 21-36-54" src="https://github.com/user-attachments/assets/28ad081f-5df1-4bf9-a4e9-d98dd36aa6b8" />

<img width="1802" height="845" alt="Screenshot from 2025-11-28 16-35-28" src="https://github.com/user-attachments/assets/c07e5b9d-8dee-4d98-90e9-aa620c7da3c7" />

<img width="3148" height="1770" alt="Screenshot from 2025-11-28 17-18-36" src="https://github.com/user-attachments/assets/135223bc-5d74-4d00-81b6-d746e88d4045" />

<img width="2560" height="349" alt="Screenshot from 2025-11-28 17-46-02" src="https://github.com/user-attachments/assets/74ba1f92-12fb-4fa6-937c-31f8aa2a275e" />
