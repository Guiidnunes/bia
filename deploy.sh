./build.sh
aws ecs update-service --cluster cluster-bia2 --service service-bia --force-new-deployment
