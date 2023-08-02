# Source

It is intended that the application will allow a user to perform a reverse image search on an image uploaded by the user. The user may optionally crop, flip or rotate the image within the application prior to uploading it.

On completion of the reverse image search, the intention is that the application will display the results, which can then be filtered and/or sorted by the user by age. The intention is for the application to support the extraction of text found within an uploaded image and translation of same from a selection of supported languages.

## Architecture

Source is a Ruby on Rails app running on GKE.

It uses [Redis](https://github.com/nateware/redis-objects) as main data storage and Google Cloud Storage for the uploaded
images.

It uses [Sidekiq](https://github.com/mperham/sidekiq) to perform asynchronously the full analysis of an uploaded image.

It is powered by the [Google Vision](https://cloud.google.com/vision/docs/) and [Google Translate](https://cloud.google.com/translate/docs/) APIs.

A simple diagram of the architecture: [Google Slide](https://docs.google.com/presentation/d/1_ze_95IGVFTVAVwjpKi_RTQSx6Uqwx7nvcykvn6xwMk/edit?usp=sharing)

## Local Development

### Generate new gcloud credentials for the project

It shouldn't be necessary, but if you need, this is how to do it:

* Open Google Cloud Console
* Go to IAM & admin > Service accounts
* Click on the menu button related to the service account created for this project (called source)
* Click on create key, select JSON as type and click create
* This should download the file on your machine

### Create an .env file in the root of the project

```bash
SECRET_KEY_BASE="<rails generated key>"

GOOGLE_APPLICATION_CREDENTIALS=/root/.ssh/<name of the file>
MASTER_PASSWORD="<random string>"
BUCKET_NAME="<google cloud bucket name>"
GOOGLE_SHEET_PASSCODES_ID='<id of the google sheet containing passcodes>'
GOOGLE_SHEET_WHITELIST_URLS_ID='<id of the google sheet containing whitelisted urls>'
REDIS_HOST=redis
REDIS_PORT=6379
```

### Using Mac?

* Duplicate docker-compose.yml and rename to docker-compose-mac.yml
* Change the line in app -> volumes from

  ```yaml
  - /usr/bin/docker:/usr/bin/docker
  ```

  to

  ```yaml
  - /usr/local/bin/docker:/usr/bin/docker
  ```

* When running docker-compose use

  ```bash
  docker-compose -f docker-compose-mac.yml
  ```

#### Build docker image

```bash
docker-compose build
```

#### Run the app

```bash
docker-compose up
```

#### Run Tests with Guard

```bash
docker-compose -f docker-compose.rspec.test.yml run -e 'RAILS_ENV=test' app rake db:create db:migrate

docker-compose -f docker-compose.rspec.test.yml run -e 'RAILS_ENV=test' app guard
```

## Deployment to Google Cloud

Google CloudBuild has been configured for this repository to enable automated
builds and deployment.

The build script will build, test and push the `nginx` and `rails`
images before finally deploying the new images to the target
environment.

## Google Cloud infrastructure Setup Instructions

Skip if already exists!

**Note: The manifest templates documented below are also stored in the `/kubernetes` directory**

# Kubernetes

* Go to Google console and create a cluster.
* Select a region (region should be the same as the db instance)
* choose number of pods
* once the cluster is created, connect to the cluster and * create a file called credentials.json
* copy the content of the service account json file you should have on your machine

create config map for credentials

```bash
kubectl create configmap config --namespace credentials --from-file credentials.json
```

From the google console:

* select the workloads and click edit
* edit the yml file using the template below

```yaml
---
apiVersion: apps/v1
kind: Deployment
metadata:
  generation: 6
  labels:
    app: <name>
  name: <name>
  namespace: default
spec:
  replicas: 1
  revisionHistoryLimit: 10
  selector:
    matchLabels:
      app: <name>
  strategy:
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 1
    type: RollingUpdate
  template:
    metadata:
      creationTimestamp: ~
      labels:
        app: <name>
    spec:
      containers:
        -
          name: sidekiq
          image: <source app>
          command: ['/bin/bash']
          args: ['-c', 'bundle exec sidekiq']
        -
          name: source-nginx
          image: <source nginx image tag>
           env:
            - name: BACKEND_HOST
              value: localhost
            - name: BACKEND_PORT
              value: 3000
            - name: LOG_FORMAT
              value: text

          - name: PROJECT_ID
            value: <project ID>
        -
          name: <name>
          image: <gcr image name>
          imagePullPolicy: IfNotPresent
          resources:
            limits:
              cpu: 2000m
              memory: 2000Mi
            requests:
              cpu: 1500m
              memory: 1000Mi
          terminationMessagePath: /dev/termination-log
          terminationMessagePolicy: File
          volumeMounts:
            -
              mountPath: /secrets/cloudsql
              name: cloudsql-instance-credentials
              readOnly: true
          env:
          - name: PROJECT_ID
            value: <project id>
          - name: BUCKET_NAME
            value: <bucket name>
          - name: BUCKET_FOLDER
            value: <bucket folder>
          - name: GOOGLE_SHEET_PASSCODES_ID
            value: <google sheet id>
          - name: GOOGLE_SHEET_WHITELIST_URLS_ID
            value: <google sheet id>
          - name: GOOGLE_APPLICATION_CREDENTIALS
            value: /secrets/cloudsql/credentials.json
          - name: RAILS_SERVE_STATIC_FILES
            value: true
          - name: GET_HOSTS_FROM
            value: dns
          - name: REDIS_HOST
            value: <ip redis master>

      dnsPolicy: ClusterFirst
      restartPolicy: Always
      schedulerName: default-scheduler
      securityContext: {}
      terminationGracePeriodSeconds: 30
      volumes:
        -
          name: cloudsql-instance-credentials
          secret:
            secretName: cloudsql-instance-credentials
```
### Expose pods with service

* go to Google Cloud console
* select Kubernetes Engine > Workloads
* select the deployment
* in the section Exposing services click on the button 'expose'
* select type 'ClusterIP'
* edit port forwarding: port = 80, targetPort= 80
* after creating the service edit the yaml file following this template:

```yaml
apiVersion: v1
kind: Service
metadata:
  labels:
    app: source
  name: source-service
  namespace: default
spec:
  clusterIP: <cluster ip>
  externalTrafficPolicy: Cluster
  ports:
    port: 80
    protocol: TCP
    targetPort: 80
  selector:
    app: source-staging
  sessionAffinity: None
  type: ClusterIP
```

### Create ingress

```yaml
---
  apiVersion: networking.k8s.io/v1
  kind: Ingress
  metadata:
    annotations:
      kubernetes.io/ingress.class: nginx
      nginx.ingress.kubernetes.io/auth-realm: Authentication Required # Only for staging
      nginx.ingress.kubernetes.io/auth-secret: basic-auth # Only for staging
      nginx.ingress.kubernetes.io/auth-type: basic  # Only for staging
      nginx.ingress.kubernetes.io/proxy-body-size: 50m
      nginx.ingress.kubernetes.io/proxy-connect-timeout: "600"
      nginx.ingress.kubernetes.io/proxy-read-timeout: "600"
      nginx.ingress.kubernetes.io/proxy-send-timeout: "600"
      nginx.org/client-max-body-size: 100m
    name: <ingress name>
    namespace: <namespace>
  spec:
    ingressClassName: nginx
    rules:
    - host: <subdomain>.organisation.com
      http:
        paths:
        - backend:
            service:
              name: <service name>
              port:
                number: 80
          path: /
          pathType: ImplementationSpecific       
```

### Redis

Follow this guide: https://cloud.google.com/kubernetes-engine/docs/tutorials/guestbook

#### Redis Master with persistent volume

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  annotations:
    deployment.kubernetes.io/revision: "4"
  generation: 6
  labels:
    app: redis
    role: master
    tier: backend
  name: redis-master
  namespace: default
spec:
  replicas: 1
  revisionHistoryLimit: 10
  selector:
    matchLabels:
      app: redis
      role: master
      tier: backend
  strategy:
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 1
    type: RollingUpdate
  template:
    metadata:
      creationTimestamp: null
      labels:
        app: redis
        role: master
        tier: backend
    spec:
      containers:
      - image: k8s.gcr.io/redis:e2e
        imagePullPolicy: IfNotPresent
        name: master
        ports:
        - containerPort: 6379
          protocol: TCP
        resources:
          requests:
            cpu: 100m
            memory: 100Mi
        terminationMessagePath: /dev/termination-log
        terminationMessagePolicy: File
        volumeMounts:
        - mountPath: /data
          name: redis-data
          subPath: redis-data
      dnsPolicy: ClusterFirst
      restartPolicy: Always
      schedulerName: default-scheduler
      securityContext: {}
      terminationGracePeriodSeconds: 30
      volumes:
      - name: redis-data
        persistentVolumeClaim:
          claimName: redis-disk
```

#### Persistent Volume

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: redis-prod-disk
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 200Gi
```

# Create nginx controller

From Google Cloud console:

* go to Kubernetes Engine > Clusters
* select the cluster (e.g. source) and click connect
* Run the following commands

```bash

# install helm
curl https://raw.githubusercontent.com/kubernetes/helm/master/scripts/get > get_helm.sh

chmod +x get_helm.sh
./get_helm.sh
helm init

kubectl create serviceaccount --namespace kube-system tiller

kubectl create clusterrolebinding tiller-cluster-rule --clusterrole=cluster-admin --serviceaccount=kube-system:tiller

kubectl patch deploy --namespace kube-system tiller-deploy -p '{"spec":{"template":{"spec":{"serviceAccount":"tiller"}}}}'

helm init --service-account tiller --upgrade
```

### Adding Helm Repository for ingress controller
```
helm repo add nginx-stable https://helm.nginx.com/stable
helm repo update
```
### Install the Chart (At initial stage only)
```
#Latest version: 
helm install controller nginx-stable/nginx-ingress

#Spesific version: 
helm install controller nginx-stable/nginx-ingress --version <chart version number>
````

### Upgrade version
```
helm upgrade controller  nginx/nginx-ingress --version <chart version number>
``` 
Refer https://artifacthub.io/packages/helm/nginx/nginx-ingress for chart version number.

# DNS

Take note of the IP address of the nginx-controller service that you can obtain by running `kubectl get services | grep nginx`

In Route53 create a record set type A with the IP of the nginx controller as value

### Cors Cloud Storage

* login with glcoud auth login
* create a file called cors.json

```json
[
    {
      "origin": ["http://exmaple.com"],
      "responseHeader": ["Content-Type"],
      "method": ["GET", "HEAD", "DELETE"],
      "maxAgeSeconds": 3600
    }
]
```

run

```bash
gsutil setcors cors.json gs://<bucket name>
```
