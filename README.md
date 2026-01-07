# Hello World - AWS App Runner

A simple static HTML page deployed with AWS App Runner.

## Build Docker Image

```bash
docker build -t hello-world-app .
docker run -p 8080:8081 hello-world-app
```

Visit `http://localhost:8080` to test locally.

## Deploy to AWS App Runner

1. Push image to ECR or Docker Hub
2. Create App Runner service from the image
3. Configure port 8081 in App Runner settings
4. Access your app via the provided URL