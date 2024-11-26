#!/bin/bash

# Étape 1 : Vérification et création du namespace
echo "Création ou vérification du namespace 'apps'..."
kubectl get namespace apps || kubectl create namespace apps

# Étape 2 : Suppression des ressources existantes
echo "Suppression complète des ressources dans le namespace 'apps'..."
kubectl delete all --all -n apps --ignore-not-found
kubectl delete configmaps --all -n apps --ignore-not-found
kubectl delete secrets --all -n apps --ignore-not-found
kubectl delete pvc --all -n apps --ignore-not-found
kubectl delete jobs --all -n apps --ignore-not-found

# Attente de la suppression complète
echo "En attente de la suppression complète des ressources..."
while kubectl get pods -n apps | grep -q 'Running\|Pending'; do
    sleep 5
    echo "En attente de suppression des Pods..."
done

# Étape 3 : Déploiement des dépendances (MySQL pour WordPress)
echo "Déploiement de MySQL pour WordPress..."
kubectl apply -f wordpress-mysql.yaml -n apps

# Vérification que MySQL est déployé et prêt
echo "Vérification de l'état de MySQL..."
while [[ $(kubectl get pods -l app=mysql -n apps -o jsonpath="{.items[0].status.phase}") != "Running" ]]; do
    echo "MySQL en cours de démarrage..."
    sleep 5
done
echo "MySQL est prêt."

# Étape 4 : Déploiement de WordPress
echo "Déploiement de WordPress..."
kubectl apply -f wordpress.yaml -n apps

# Étape 5 : Déploiement de Prometheus
echo "Création et application du ConfigMap prometheus-config.yaml..."
cat > prometheus-config.yaml <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: prometheus-config
  namespace: apps
data:
  prometheus.yml: |
    global:
      scrape_interval: 15s

    scrape_configs:
      - job_name: 'prometheus'
        static_configs:
          - targets: ['localhost:9090']

      - job_name: 'cadvisor'
        static_configs:
          - targets: ['cadvisor.apps.svc.cluster.local:8080']

      - job_name: 'node-exporter'
        static_configs:
          - targets: ['node-exporter.apps.svc.cluster.local:9100']

      - job_name: 'wordpress'
        metrics_path: /wp-content/plugins/prometheus-exporter/metrics
        static_configs:
          - targets: ['wordpress.apps.svc.cluster.local:80']
EOF

kubectl apply -f prometheus-config.yaml

echo "Création et application du déploiement Prometheus..."
cat > prometheus.yaml <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: prometheus
  namespace: apps
  labels:
    app: prometheus
spec:
  replicas: 1
  selector:
    matchLabels:
      app: prometheus
  template:
    metadata:
      labels:
        app: prometheus
    spec:
      containers:
        - name: prometheus
          image: prom/prometheus:v2.46.0
          args:
            - "--config.file=/etc/prometheus/prometheus.yml"
          ports:
            - containerPort: 9090
          volumeMounts:
            - name: prometheus-config-volume
              mountPath: /etc/prometheus/
      volumes:
        - name: prometheus-config-volume
          configMap:
            name: prometheus-config

---

apiVersion: v1
kind: Service
metadata:
  name: prometheus
  namespace: apps
  labels:
    app: prometheus
spec:
  type: LoadBalancer
  ports:
    - port: 9090
      targetPort: 9090
  selector:
    app: prometheus
EOF

kubectl apply -f prometheus.yaml

# Étape 6 : Déploiement de cAdvisor
echo "Déploiement de cAdvisor..."
kubectl apply -f cadvisor.yaml -n apps

# Étape 7 : Déploiement de Node Exporter
echo "Déploiement de Node Exporter..."
kubectl apply -f node-exporter.yaml -n apps

# Étape 8 : Déploiement de Grafana
echo "Déploiement de Grafana..."
kubectl apply -f grafana.yaml -n apps

# Étape 9 : Déploiement de GLPI
echo "Déploiement de GLPI..."
kubectl apply -f glpi.yaml -n apps

# Étape 10 : Vérification des services et des Pods
echo "Vérification des services dans le namespace 'apps'..."
kubectl get svc -n apps

echo "Vérification des Pods dans le namespace 'apps'..."
kubectl get pods -n apps

echo "Script terminé avec succès."
