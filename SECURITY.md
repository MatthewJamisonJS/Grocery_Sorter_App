# Security Guide

> **WARNING:** Google API integration is currently **DISABLED**. Credentials are NOT required for core app functionality. Google Docs features are non-functional until further notice.

## 🔐 Credential Management

This application requires Google API credentials to function. **Never commit your actual credentials to version control.**

### Required Credentials

1. **Google API Credentials** (`config/client_secrets.json`)
   - Required for Google Docs API access
   - Contains OAuth 2.0 client ID and secret
   - **NEVER commit this file to git**

2. **OAuth Tokens** (`config/tokens.yaml`)
   - Generated automatically after first OAuth flow
   - Contains access and refresh tokens
   - **NEVER commit this file to git**

### Setup Instructions

1. **Copy the example file:**
   ```bash
   cp config/client_secrets.example.json config/client_secrets.json
   ```

2. **Get your Google API credentials:**
   - Go to [Google Cloud Console](https://console.cloud.google.com/)
   - Create a new project or select existing one
   - Enable Google Docs API
   - Create OAuth 2.0 credentials
   - Download the JSON file
   - Replace the contents of `config/client_secrets.json` with your actual credentials

3. **Run the application:**
   ```bash
   ruby script/grocery_sorter.rb
   ```
   - The app will automatically handle OAuth flow
   - Tokens will be stored in `config/tokens.yaml`

### Security Best Practices

- ✅ Use environment variables for production deployments
- ✅ Rotate credentials regularly
- ✅ Never share credentials in issues or discussions
- ✅ Use different credentials for development and production
- ❌ Never commit `client_secrets.json` or `tokens.yaml`
- ❌ Never share credentials in public repositories
- ❌ Never hardcode credentials in source code

### Environment Variables (Recommended for Production)

For production deployments, consider using environment variables:

```bash
export GOOGLE_CLIENT_ID="your-client-id"
export GOOGLE_CLIENT_SECRET="your-client-secret"
export GOOGLE_PROJECT_ID="your-project-id"
```

### Reporting Security Issues

If you discover a security vulnerability, please report it privately:
- **Email**: [Your email]
- **GitHub**: Create a private security advisory

**Do not create public issues for security vulnerabilities.**

## 🔍 Security Checklist

Before making this project public, ensure:

- [ ] No credentials are committed to git history
- [ ] `.gitignore` excludes all sensitive files
- [ ] Example files are provided for setup
- [ ] Security documentation is complete
- [ ] Environment variable support is implemented
- [ ] Debug scripts are removed or secured
- [ ] No hardcoded secrets in source code
- [ ] OAuth scopes are minimal and appropriate
- [ ] Error messages don't leak sensitive information 