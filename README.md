# AWS App Runner - Node.js Static Site

Simple Node.js + Express application deployed to AWS App Runner with automated CI/CD using GitHub Actions and OIDC authentication.

## 🏗️ Architecture

```
GitHub (main branch push)
    ↓
GitHub Actions (OIDC auth)
    ↓
Docker Build (linux/amd64)
    ↓
Amazon ECR (:latest)
    ↓
AWS App Runner (auto-deploy)
```

## 🚀 Quick Start

### Local Development

```bash
# Build (⚠️ Mac M1/M2/M3: use --platform linux/amd64)
docker build --platform linux/amd64 -t hello-world .

# Run
docker run -p 8080:8081 hello-world

# Test at http://localhost:8080
```

### First Deployment

1. **Create ECR repository** (AWS Console → ECR)
2. **Push initial image:**
   ```bash
   export AWS_REGION=eu-central-1
   export AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
   export ECR_REPOSITORY=apprunner-nginx
   
   # Login to ECR
   aws ecr get-login-password --region $AWS_REGION | \
     docker login --username AWS --password-stdin \
     $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com
   
   # Build, tag, push
   docker build --platform linux/amd64 -t $ECR_REPOSITORY .
   docker tag $ECR_REPOSITORY:latest \
     $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$ECR_REPOSITORY:latest
   docker push $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$ECR_REPOSITORY:latest
   ```

3. **Create App Runner service** (AWS Console → App Runner):
   - Source: ECR, repository `apprunner-nginx`, tag `latest`
   - Deployment: **Automatic**
   - Port: **8081**
   - Health check: **HTTP**, path `/`

## 🔐 CI/CD Setup (OIDC)

### 1. Configure AWS OIDC Provider

**IAM Console → Identity providers → Add provider:**
- Provider type: `OpenID Connect`
- Provider URL: `https://token.actions.githubusercontent.com`
- Audience: `sts.amazonaws.com`

### 2. Create IAM Policy

**IAM Console → Policies → Create policy:**

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ecr:GetAuthorizationToken",
        "ecr:BatchCheckLayerAvailability",
        "ecr:GetDownloadUrlForLayer",
        "ecr:BatchGetImage",
        "ecr:PutImage",
        "ecr:InitiateLayerUpload",
        "ecr:UploadLayerPart",
        "ecr:CompleteLayerUpload",
        "ecr:DescribeRepositories",
        "ecr:ListImages"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "apprunner:StartDeployment",
        "apprunner:DescribeService"
      ],
      "Resource": "*"
    }
  ]
}
```

Name: `GitHubActionsAppRunnerPolicy`

### 3. Create IAM Role

**IAM Console → Roles → Create role:**
- Trusted entity: `Web identity`
- Identity provider: `token.actions.githubusercontent.com`
- Audience: `sts.amazonaws.com`
- GitHub organization: `<your-username>`
- GitHub repository: `<your-repo>`
- GitHub branch: `main`
- Attach policy: `GitHubActionsAppRunnerPolicy`
- Role name: `GitHubActionsAppRunnerRole`

### 4. Configure GitHub Secrets

**GitHub → Settings → Secrets and variables → Actions:**

| Name | Value |
|------|-------|
| `AWS_ROLE_ARN` | `arn:aws:iam::<ACCOUNT_ID>:role/GitHubActionsAppRunnerRole` |
| `APPRUNNER_SERVICE_ARN` | `arn:aws:apprunner:<region>:<account>:service/<name>/<id>` |

### 5. GitHub Actions Workflow

File `.github/workflows/deploy.yml` is configured to:
- Trigger on push to `main`
- Authenticate via OIDC (no access keys!)
- Build Docker image for `linux/amd64`
- Push to ECR with tags `:latest` and `:${{ github.sha }}`
- App Runner auto-detects and deploys

## 📝 Project Structure

```
.
├── .github/
│   └── workflows/
│       └── deploy.yml          # CI/CD pipeline
├── Dockerfile                  # Node.js app (port 8081)
├── server.js                   # Express server
├── package.json               # Dependencies
├── index.html                 # Static content
├── apprunner.yaml             # App Runner config
└── README.md
```

## ⚙️ Key Configuration

### Port 8081
All components use port **8081**:
- `server.js`: `app.listen(8081, '0.0.0.0')`
- `Dockerfile`: `EXPOSE 8081`
- `apprunner.yaml`: `port: 8081`
- App Runner health check: Port `8081`

### Platform: linux/amd64
⚠️ **Critical for Mac M1/M2/M3 users:**
Always build with `--platform linux/amd64` - App Runner runs on x86 architecture.

### Health Check
- Protocol: **HTTP** (not TCP!)
- Path: `/`
- Port: `8081`

## 🔧 Troubleshooting

### Container exit code 255
- **Cause:** Wrong architecture (ARM instead of x86)
- **Fix:** Build with `--platform linux/amd64`

### Health check fails
- **Cause:** Wrong protocol or port
- **Fix:** Set health check to HTTP, path `/`, port `8081`

### OIDC authentication fails
- **Check:**
  - OIDC provider configured
  - Role trust policy allows your repo
  - Workflow has `permissions: id-token: write`

### Deployment not triggering
- **Cause:** App Runner already auto-deploying from ECR
- **Fix:** Remove manual `start-deployment` step (not needed with auto-deploy)

## 🎯 Benefits of OIDC

✅ No long-term credentials in GitHub  
✅ Tokens valid for 1 hour only  
✅ Automatic credential rotation  
✅ Precise audit trail (repo + branch + commit)  
✅ AWS security best practice  

## 📚 References

- [AWS App Runner Documentation](https://docs.aws.amazon.com/apprunner/)
- [GitHub OIDC with AWS](https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/configuring-openid-connect-in-amazon-web-services)
- [ECR Documentation](https://docs.aws.amazon.com/ecr/)

---

**Version:** 1.0  
**Last Updated:** 2026-01-09