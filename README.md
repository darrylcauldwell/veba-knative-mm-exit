Background reading to this repository

https://darrylcauldwell.github.io/post/veba-knative/

# Install Function

```bash
# SSH to VEBA appliance
kubectl apply -f https://raw.githubusercontent.com/darrylcauldwell/veba-knative-mm-exit/master/exit-mm-service.yml
kubectl apply -f https://raw.githubusercontent.com/darrylcauldwell/veba-knative-mm-exit/master/exit-mm-trigger.yml
```

# Update Function

1. Clone to local repository like:

```bash
git clone https://github.com/darrylcauldwell/veba-knative-mm-exit.git
cd veba-knative-mm-exit
```

2. Update handler.ps1 with required business logic

3. Create new local image and push to GitHub Container Registry incrementing the version in tag like:

```bash
# Authenticate if necessary with docker login
docker build --tag ghcr.io/darrylcauldwell/veba-ps-exit-mm:0.2 .
docker push ghcr.io/darrylcauldwell/veba-ps-exit-mm:0.2
```

4. Update Knative service manifest ( exit-mm-service.yml ) to reflect new docker container image version lie:

```
- image: ghcr.io/darrylcauldwell/veba-ps-exit-mm:0.2
```

5. Once container uploaded remove and recreate Knative resourcs like:

```bash
# SSH to VEBA appliance
kubectl delete -f https://raw.githubusercontent.com/darrylcauldwell/veba-knative-mm-exit/master/exit-mm-service.yml
kubectl delete -f https://raw.githubusercontent.com/darrylcauldwell/veba-knative-mm-exit/master/exit-mm-trigger.yml
kubectl apply -f https://raw.githubusercontent.com/darrylcauldwell/veba-knative-mm-exit/master/exit-mm-service.yml
kubectl apply -f https://raw.githubusercontent.com/darrylcauldwell/veba-knative-mm-exit/master/exit-mm-trigger.yml
```
