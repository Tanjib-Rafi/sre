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

## Screenshots
<img width="3746" height="876" alt="Screenshot from 2025-11-27 23-14-58" src="https://github.com/user-attachments/assets/a3126c92-349e-42ec-a9b9-0cf89704d941" />
<img width="3216" height="1428" alt="Screenshot from 2025-11-27 23-04-14" src="https://github.com/user-attachments/assets/6ac0146e-d08a-494a-bddb-b9da825b4c38" />
<img width="1252" height="764" alt="Screenshot from 2025-11-27 21-36-54" src="https://github.com/user-attachments/assets/159b4dd2-1789-4c78-a3c4-848da0bd900e" />
