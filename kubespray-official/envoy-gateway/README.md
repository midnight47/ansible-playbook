helm template eg-crds oci://docker.io/envoyproxy/gateway-crds-helm \
  --version v1.7.3 \
  -f envoy-gateway-crds-values.yaml \
  | kubectl apply --server-side -f -



kubectl apply -f - <<'EOF'
apiVersion: v1
kind: Namespace
metadata:
  name: envoy-gateway-system
  labels:
    app.kubernetes.io/name: envoy-gateway
EOF



helm upgrade --install eg oci://docker.io/envoyproxy/gateway-helm \
  --version v1.7.3 \
  -n envoy-gateway-system \
  --create-namespace \
  --skip-crds \
  -f envoy-gateway-values.yaml


ждём контроллер

kubectl wait --timeout=5m \
  -n envoy-gateway-system \
  deployment/envoy-gateway \
  --for=condition=Available



kubectl apply -f gateway-public.yaml



проверка
kubectl get pods -n envoy-gateway-system
kubectl get gatewayclass
kubectl get gateway -n envoy-gateway-system
kubectl get svc -n envoy-gateway-system -o wide



запускаем тестовый деплоймент

kubectl apply -f echo-test.yaml