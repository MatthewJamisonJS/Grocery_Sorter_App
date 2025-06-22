# Ollama Security Configuration Guide

## ⚠️ Security Warning

Based on recent security research, Ollama can be vulnerable to unauthorized access if not properly configured. This guide helps you secure your Ollama installation.

## Security Vulnerabilities Addressed

1. **Unauthenticated Access**: Ollama's default port (11434) can be exposed without authentication
2. **Path Traversal**: Older versions had CVE-2024-37032 vulnerability
3. **Resource Abuse**: APIs can be spammed for DoS attacks
4. **Data Leakage**: Private models can be accessed without permission

## Recommended Security Measures

### 1. Run Ollama Locally Only (Recommended)

```bash
# Start Ollama with localhost binding only
ollama serve --host 127.0.0.1:11434
```

### 2. Use Firewall Rules

```bash
# macOS (using pfctl)
sudo pfctl -e
echo "block drop in proto tcp from any to any port 11434" | sudo pfctl -f -

# Linux (using iptables)
sudo iptables -A INPUT -p tcp --dport 11434 -s 127.0.0.1 -j ACCEPT
sudo iptables -A INPUT -p tcp --dport 11434 -j DROP
```

### 3. Use Reverse Proxy with Authentication

#### NGINX Configuration

```nginx
# /etc/nginx/sites-available/ollama
server {
    listen 443 ssl;
    server_name your-domain.com;

    ssl_certificate /path/to/cert.pem;
    ssl_certificate_key /path/to/key.pem;

    location / {
        proxy_pass http://localhost:11434;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;

        # Basic authentication
        auth_basic "Ollama Admin";
        auth_basic_user_file /etc/nginx/ollama.htpasswd;

        # Rate limiting
        limit_req zone=ollama burst=10 nodelay;
        limit_req_zone $binary_remote_addr zone=ollama:10m rate=1r/s;
    }
}
```

#### Create Password File

```bash
# Install htpasswd utility
sudo apt-get install apache2-utils  # Ubuntu/Debian
brew install httpd                   # macOS

# Create password file
sudo htpasswd -c /etc/nginx/ollama.htpasswd your_username
```

### 4. Environment Variables for API Key

```bash
# Set API key for additional security
export OLLAMA_API_KEY="your-secure-api-key-here"

# Or add to your shell profile
echo 'export OLLAMA_API_KEY="your-secure-api-key-here"' >> ~/.bashrc
```

### 5. Update Ollama Regularly

```bash
# Check for updates
ollama --version

# Update to latest version
curl -fsSL https://ollama.ai/install.sh | sh
```

## Application-Specific Security

The Grocery Sorter application includes built-in security measures:

1. **Host Validation**: Only allows localhost connections
2. **Rate Limiting**: Limits requests to 60 per minute
3. **Timeout Protection**: Prevents hanging connections
4. **Secure Headers**: Adds proper User-Agent and Content-Type headers

## Testing Security

```bash
# Test if Ollama is accessible from outside
curl -I http://your-server:11434/api/tags

# Should return 403 or connection refused if properly secured
```

## Troubleshooting

### Connection Issues
- Ensure Ollama is running: `ollama serve`
- Check firewall settings
- Verify localhost binding

### Authentication Issues
- Check API key configuration
- Verify reverse proxy settings
- Test with curl: `curl -H "Authorization: Bearer YOUR_KEY" http://localhost:11434/api/tags`

## Additional Resources

- [Ollama Security Documentation](https://github.com/ollama/ollama/blob/main/docs/security.md)
- [CVE-2024-37032 Details](https://nvd.nist.gov/vuln/detail/CVE-2024-37032)
- [Ollama Troubleshooting Guide](https://github.com/ollama/ollama/blob/main/docs/troubleshooting.md)

## Security Checklist

- [ ] Ollama running on localhost only
- [ ] Firewall rules configured
- [ ] Reverse proxy with authentication (if external access needed)
- [ ] API key configured
- [ ] Regular updates enabled
- [ ] Rate limiting enabled
- [ ] SSL/TLS configured (if external access)
- [ ] Security headers configured
- [ ] Access logs monitored 