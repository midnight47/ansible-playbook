https://github.com/seaweedfs/seaweedfs-csi-driver/tree/master/deploy/helm/seaweedfs-csi-driver


helm repo add seaweedfs-csi-driver https://seaweedfs.github.io/seaweedfs-csi-driver/helm
helm repo update

helm install seaweedfs-csi-driver seaweedfs-csi-driver/seaweedfs-csi-driver   --namespace seaweedfs-csi-driver   --create-namespace   -f values.yaml --version 0.2.2

протестировать можно так 
kubectl apply -f pvc-test.yaml -n seaweedfs-csi-driver 

root@kub-master1:~/seaweedfs-provision# kubectl  get pvc -n seaweedfs-csi-driver 
NAME                STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS        VOLUMEATTRIBUTESCLASS   AGE
seaweedfs-csi-pvc   Bound    pvc-d4435cb0-2469-45bc-9d4e-79507eda7dc6   5Gi        RWO            seaweedfs-storage   <unset>                 10s

root@kub-master1:~/seaweedfs-provision# kubectl get pv -n seaweedfs-csi-driver 
NAME                                       CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM                                    STORAGECLASS        VOLUMEATTRIBUTESCLASS   REASON   AGE
pvc-d4435cb0-2469-45bc-9d4e-79507eda7dc6   5Gi        RWO            Delete           Bound    seaweedfs-csi-driver/seaweedfs-csi-pvc   seaweedfs-storage   <unset>                          25s
