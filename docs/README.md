# API Documentation Deployment

This directory contains the generated API documentation for Auth0.swift, which is automatically deployed to [GitHub Pages](https://auth0.github.io/Auth0.swift/documentation/auth0).

## How It Works

### Generating Documentation

The documentation is generated using Apple's DocC (Documentation Compiler) through the `build_docs` fastlane lane:

```bash
bundle exec fastlane build_docs
```

This command:
1. Builds the documentation from the Swift DocC catalog (`Documentation.docc/`)
2. Generates a static website in the `docs/` directory
3. Creates an index.html redirect to the main documentation page

### Deploying to GitHub Pages

The documentation is automatically deployed to GitHub Pages via the **Deploy API Documentation** workflow (`.github/workflows/deploy-docs.yml`).

#### Automatic Deployment

The workflow automatically deploys when:
- Changes are pushed to the `master` branch that affect:
  - The `docs/` directory
  - The workflow file itself

#### Manual Deployment

You can also manually trigger the deployment:
1. Go to the [Actions tab](https://github.com/auth0/Auth0.swift/actions/workflows/deploy-docs.yml)
2. Click "Run workflow"
3. Select the branch (typically `master`)
4. Click "Run workflow"

## Workflow Details

The deployment workflow:
1. Checks out the repository
2. Configures GitHub Pages
3. Uploads the `docs/` directory as a Pages artifact
4. Deploys the artifact to GitHub Pages

## Accessing the Documentation

Once deployed, the documentation is available at:
- **Main URL**: https://auth0.github.io/Auth0.swift/documentation/auth0
- **Root URL**: https://auth0.github.io/Auth0.swift/ (redirects to main URL)

## Prerequisites

For the deployment to work, GitHub Pages must be enabled in the repository settings:
1. Go to Repository Settings → Pages
2. Source should be set to "GitHub Actions"

## Local Development

To preview the documentation locally:
1. Generate the docs: `bundle exec fastlane build_docs`
2. Serve the docs with a local web server:
   ```bash
   cd docs
   python3 -m http.server 8000
   ```
3. Open http://localhost:8000 in your browser

## Troubleshooting

### Documentation not updating
- Ensure the `docs/` directory contains the latest generated documentation
- Check that the workflow ran successfully in the Actions tab
- Verify GitHub Pages is enabled and set to deploy from GitHub Actions

### 404 errors
- Make sure the `index.html` redirect file exists in the `docs/` directory
- Verify the hosting base path matches the repository name (`Auth0.swift`)
