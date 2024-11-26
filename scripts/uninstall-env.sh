#!/bin/bash

echo "Suppression de toutes les ressources dans le namespace 'apps'..."
kubectl delete all --all -n apps
kubectl delete namespace apps

echo "Suppression complète terminée."
