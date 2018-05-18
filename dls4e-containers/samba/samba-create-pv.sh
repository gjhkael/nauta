#!/bin/bash -e
set -e

function hide_output() {
  $@ 2>/dev/null >/dev/null || return $?
  return 0
}

function pv_exists() {
    hide_output kubectl get pv $1 || return $?
    return 0
}

USER=$1

INPUT_PV=$(kubectl -n dls4e get pvc ${INPUT_PVC} -o jsonpath={.spec.volumeName})
OUTPUT_PV=$(kubectl -n dls4e get pvc ${OUTPUT_PVC} -o jsonpath={.spec.volumeName})

INPUT_NFS_SERVER=$(kubectl get pv ${INPUT_PV} -o jsonpath={.spec.nfs.server})
INPUT_NFS_PATH=$(kubectl get pv ${INPUT_PV} -o jsonpath={.spec.nfs.path})

OUTPUT_NFS_SERVER=$(kubectl get pv ${OUTPUT_PV} -o jsonpath={.spec.nfs.server})
OUTPUT_NFS_PATH=$(kubectl get pv ${OUTPUT_PV} -o jsonpath={.spec.nfs.path})

INPUT_HOME_NAME=${APP_RELEASE}-${USER}-input-home
INPUT_PUB_NAME=${APP_RELEASE}-${USER}-input-public

OUTPUT_HOME_NAME=${APP_RELEASE}-${USER}-output-home
OUTPUT_PUB_NAME=${APP_RELEASE}-${USER}-output-public

if ! pv_exists ${INPUT_HOME_NAME}; then
    echo """
apiVersion: v1
kind: PersistentVolume
metadata:
  name: ${INPUT_HOME_NAME}
  labels:
    app_name: ${APP_RELEASE}
    user: ${USER}
    type: input
    share: private
spec:
  accessModes:
  - ReadOnlyMany
  capacity:
    storage: 32Gi
  nfs:
    path: ${INPUT_NFS_PATH}/${USER}
    server: ${INPUT_NFS_SERVER}
  persistentVolumeReclaimPolicy: Retain
  storageClassName: ""
    """ | hide_output kubectl create -f -
fi


if ! pv_exists ${INPUT_PUB_NAME}; then
    echo """
apiVersion: v1
kind: PersistentVolume
metadata:
  name: ${INPUT_PUB_NAME}
  labels:
    app_name: ${APP_RELEASE}
    user: ${USER}
    type: input
    share: public
spec:
  accessModes:
  - ReadOnlyMany
  capacity:
    storage: 32Gi
  nfs:
    path: ${INPUT_NFS_PATH}
    server: ${INPUT_NFS_SERVER}
  persistentVolumeReclaimPolicy: Retain
  storageClassName: ""
    """ | hide_output kubectl create -f -
fi

if ! pv_exists ${OUTPUT_HOME_NAME}; then
    echo """
apiVersion: v1
kind: PersistentVolume
metadata:
  name: ${OUTPUT_HOME_NAME}
  labels:
    app_name: ${APP_RELEASE}
    user: ${USER}
    type: output
    share: private
spec:
  accessModes:
  - ReadWriteMany
  capacity:
    storage: 32Gi
  nfs:
    path: ${OUTPUT_NFS_PATH}/${USER}
    server: ${OUTPUT_NFS_SERVER}
  persistentVolumeReclaimPolicy: Retain
  storageClassName: ""
    """ | hide_output kubectl create -f -
fi


if ! pv_exists ${OUTPUT_PUB_NAME}; then
    echo """
apiVersion: v1
kind: PersistentVolume
metadata:
  name: ${OUTPUT_PUB_NAME}
  labels:
    app_name: ${APP_RELEASE}
    user: ${USER}
    type: output
    share: public
spec:
  accessModes:
  - ReadWriteMany
  capacity:
    storage: 32Gi
  nfs:
    path: ${OUTPUT_NFS_PATH}
    server: ${OUTPUT_NFS_SERVER}
  persistentVolumeReclaimPolicy: Retain
  storageClassName: ""
    """ | hide_output kubectl create -f -
fi
