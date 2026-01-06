# Deployment Guide - Mobile CoWorkly

This guide covers deploying the CoWorkly application to production environments.

## 📋 Table of Contents
1. [Backend Deployment](#backend-deployment)
2. [Database Setup](#database-setup)
3. [Frontend Deployment](#frontend-deployment)
4. [Environment Configuration](#environment-configuration)
5. [Security Checklist](#security-checklist)

---

## Backend Deployment

### Option 1: Deploy to Heroku

1. **Install Heroku CLI:**
   ```bash
   npm install -g heroku
   ```

2. **Login to Heroku:**
   ```bash
   heroku login
   ```

3. **Create Heroku App:**
   ```bash
   cd server
   heroku create coworkly-api
   ```

4. **Add PostgreSQL Database:**
   ```bash
   heroku addons:create heroku-postgresql:hobby-dev
   ```

5. **Set Environment Variables:**
   ```bash
   heroku config:set JWT_SECRET="your-production-jwt-secret"
   heroku config:set JWT_REFRESH_SECRET="your-production-refresh-secret"
   heroku config:set NODE_ENV="production"
   ```

6. **Deploy:**
   ```bash
   git push heroku main
   ```

7. **Run Migrations:**
   ```bash
   heroku run npx prisma migrate deploy
   ```

8. **Seed Database (optional):**
   ```bash
   heroku run npm run seed
   ```

### Option 2: Deploy to Railway

1. **Create account at railway.app**

2. **Install Railway CLI:**
   ```bash
   npm install -g @railway/cli
   ```

3. **Login and Initialize:**
   ```bash
   railway login
   railway init
   ```

4. **Add PostgreSQL:**
   ```bash
   railway add postgresql
   ```

5. **Set Environment Variables:**
   ```bash
   railway variables set JWT_SECRET="your-production-jwt-secret"
   railway variables set JWT_REFRESH_SECRET="your-production-refresh-secret"
   ```

6. **Deploy:**
   ```bash
   railway up
   ```

### Option 3: Deploy to VPS (Ubuntu/Debian)

1. **Update System:**
   ```bash
   sudo apt update
   sudo apt upgrade -y
   ```

2. **Install Node.js:**
   ```bash
   curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
   sudo apt install -y nodejs
   ```

3. **Install PostgreSQL:**
   ```bash
   sudo apt install postgresql postgresql-contrib
   ```

4. **Setup PostgreSQL:**
   ```bash
   sudo -u postgres psql
   CREATE DATABASE coworkly;
   CREATE USER coworkly_user WITH PASSWORD 'secure_password';
   GRANT ALL PRIVILEGES ON DATABASE coworkly TO coworkly_user;
   \q
   ```

5. **Clone Repository:**
   ```bash
   cd /var/www
   git clone <your-repo-url> coworkly
   cd coworkly/server
   ```

6. **Install Dependencies:**
   ```bash
   npm ci --production
   ```

7. **Setup Environment:**
   ```bash
   cp .env.example .env
   nano .env  # Edit with production values
   ```

8. **Run Migrations:**
   ```bash
   npx prisma migrate deploy
   ```

9. **Install PM2:**
   ```bash
   sudo npm install -g pm2
   ```

10. **Start Application:**
    ```bash
    pm2 start index.js --name coworkly-api
    pm2 startup
    pm2 save
    ```

11. **Setup Nginx (optional):**
    ```bash
    sudo apt install nginx
    sudo nano /etc/nginx/sites-available/coworkly
    ```

    Add configuration:
    ```nginx
    server {
        listen 80;
        server_name api.coworkly.com;

        location / {
            proxy_pass http://localhost:4000;
            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection 'upgrade';
            proxy_set_header Host $host;
            proxy_cache_bypass $http_upgrade;
        }
    }
    ```

    Enable site:
    ```bash
    sudo ln -s /etc/nginx/sites-available/coworkly /etc/nginx/sites-enabled/
    sudo nginx -t
    sudo systemctl restart nginx
    ```

12. **Setup SSL with Let's Encrypt:**
    ```bash
    sudo apt install certbot python3-certbot-nginx
    sudo certbot --nginx -d api.coworkly.com
    ```

---

## Database Setup

### Production Database Recommendations

1. **Use Managed Database Services:**
   - AWS RDS PostgreSQL
   - Google Cloud SQL
   - Azure Database for PostgreSQL
   - DigitalOcean Managed Databases
   - Railway PostgreSQL
   - Heroku Postgres

2. **Database Configuration:**
   ```env
   DATABASE_URL="postgresql://user:password@host:5432/dbname?schema=public&sslmode=require"
   ```

3. **Enable SSL/TLS:**
   - Always use SSL connections in production
   - Add `sslmode=require` to connection string

4. **Backup Strategy:**
   - Enable automated daily backups
   - Test restore procedures regularly
   - Keep backups for at least 30 days

5. **Connection Pooling:**
   Update `lib/prisma.js` for production:
   ```javascript
   const prisma = new PrismaClient({
     datasources: {
       db: {
         url: process.env.DATABASE_URL,
       },
     },
     log: ['error', 'warn'],
   });
   ```

---

## Frontend Deployment

### Build Flutter App

#### For Android (APK):
```bash
cd flutter_coworkly
flutter build apk --release
```

Output: `build/app/outputs/flutter-apk/app-release.apk`

#### For Android (App Bundle):
```bash
flutter build appbundle --release
```

Output: `build/app/outputs/bundle/release/app-release.aab`

#### For iOS:
```bash
flutter build ios --release
```

Then use Xcode to archive and upload to App Store.

### Update API Endpoint

Before building, update the API endpoint in:
`lib/services/api_config.dart`

```dart
class ApiConfig {
  static const String baseUrl = 'https://api.coworkly.com';
  // ... rest of the code
}
```

### Publish to Stores

#### Google Play Store:
1. Create app in Google Play Console
2. Upload App Bundle (`.aab` file)
3. Complete store listing
4. Submit for review

#### Apple App Store:
1. Create app in App Store Connect
2. Archive and upload via Xcode
3. Complete store listing
4. Submit for review

---

## Environment Configuration

### Production Environment Variables

Create a secure `.env` file with strong secrets:

```env
# Server
PORT=4000
NODE_ENV=production

# Database
DATABASE_URL="postgresql://user:strong_password@host:5432/coworkly?schema=public&sslmode=require"

# JWT Secrets (Generate strong random strings)
JWT_SECRET="<generate-with-openssl-rand-hex-64>"
JWT_REFRESH_SECRET="<generate-with-openssl-rand-hex-64>"

# CORS (optional)
CORS_ORIGINS="https://coworkly.com,https://app.coworkly.com"
```

### Generate Secure Secrets

Use OpenSSL to generate random secrets:
```bash
openssl rand -hex 64
```

Or Node.js:
```bash
node -e "console.log(require('crypto').randomBytes(64).toString('hex'))"
```

---

## Security Checklist

### Backend Security

- [ ] Use strong JWT secrets (at least 64 characters)
- [ ] Enable HTTPS/SSL certificates
- [ ] Set `NODE_ENV=production`
- [ ] Configure CORS properly
- [ ] Use environment variables for secrets
- [ ] Enable rate limiting
- [ ] Keep dependencies updated
- [ ] Use PostgreSQL with SSL
- [ ] Implement database backups
- [ ] Configure firewall rules
- [ ] Use reverse proxy (Nginx/Apache)
- [ ] Enable logging and monitoring
- [ ] Remove console.logs in production
- [ ] Sanitize user inputs
- [ ] Implement request validation

### Database Security

- [ ] Use strong database passwords
- [ ] Enable SSL/TLS connections
- [ ] Restrict database access by IP
- [ ] Regular security updates
- [ ] Enable audit logging
- [ ] Implement backup encryption
- [ ] Use connection pooling
- [ ] Monitor slow queries

### Frontend Security

- [ ] Store tokens securely
- [ ] Implement certificate pinning
- [ ] Use HTTPS only
- [ ] Validate all inputs
- [ ] Implement proper error handling
- [ ] Use ProGuard/R8 for Android
- [ ] Enable code obfuscation

### Infrastructure Security

- [ ] Keep OS updated
- [ ] Configure firewall
- [ ] Use SSH keys (disable password auth)
- [ ] Enable fail2ban
- [ ] Regular security audits
- [ ] Monitor logs
- [ ] Implement intrusion detection
- [ ] Use CDN for static assets

---

## Monitoring & Logging

### Backend Monitoring

**Recommended Services:**
- Sentry (Error tracking)
- LogRocket (Session replay)
- New Relic (Performance monitoring)
- DataDog (Infrastructure monitoring)

**Setup Example with PM2:**
```bash
pm2 install pm2-logrotate
pm2 set pm2-logrotate:max_size 10M
pm2 set pm2-logrotate:retain 30
```

### Database Monitoring

- Monitor connection pool usage
- Track slow queries
- Set up alerts for downtime
- Monitor disk space
- Track query performance

---

## Scaling Considerations

### Horizontal Scaling

1. **Load Balancer:**
   - Use Nginx or cloud load balancer
   - Distribute traffic across multiple instances

2. **Stateless Backend:**
   - Store sessions in database/Redis
   - Use JWT for authentication

3. **Database:**
   - Implement read replicas
   - Use connection pooling
   - Consider sharding for large scale

### Caching

1. **Redis Integration:**
   ```bash
   npm install redis
   ```

2. **Cache frequently accessed data:**
   - Room listings
   - User profiles
   - Statistics

### CDN

- Use CloudFlare or AWS CloudFront
- Cache static assets
- Reduce latency globally

---

## Rollback Plan

1. **Keep Previous Version:**
   ```bash
   pm2 save
   cp -r /var/www/coworkly /var/www/coworkly-backup
   ```

2. **Database Migrations:**
   - Always backup before migrations
   - Test rollback procedures
   - Keep migration history

3. **Quick Rollback:**
   ```bash
   pm2 stop coworkly-api
   cd /var/www/coworkly-backup
   pm2 start index.js --name coworkly-api
   ```

---

## Post-Deployment Testing

1. **Health Check:**
   ```bash
   curl https://api.coworkly.com/health
   ```

2. **Test Authentication:**
   - Register new user
   - Login
   - Access protected routes

3. **Test Core Features:**
   - Room browsing
   - Reservations
   - Notifications
   - Admin functions

4. **Performance Testing:**
   - Use Apache Bench or k6
   - Monitor response times
   - Check error rates

---

## Maintenance

### Regular Tasks

**Daily:**
- Check error logs
- Monitor server resources
- Review failed requests

**Weekly:**
- Database backups verification
- Security patches review
- Performance metrics analysis

**Monthly:**
- Dependency updates
- Security audit
- Capacity planning
- Cost optimization review

---

## Support & Troubleshooting

### Common Issues

**Database Connection Failed:**
```bash
# Check PostgreSQL status
sudo systemctl status postgresql

# Check connection
psql -h localhost -U coworkly_user -d coworkly
```

**Port Already in Use:**
```bash
# Find process using port
sudo lsof -i :4000

# Kill process
sudo kill -9 <PID>
```

**High Memory Usage:**
```bash
# Check Node process
ps aux | grep node

# Restart with PM2
pm2 restart coworkly-api
```

### Get Help

- Check logs: `pm2 logs coworkly-api`
- Monitor: `pm2 monit`
- Database logs: `sudo tail -f /var/log/postgresql/postgresql-*.log`

---

## Conclusion

This deployment guide covers the essential steps for deploying the CoWorkly application to production. Always test thoroughly in a staging environment before deploying to production, and maintain regular backups and monitoring.

For additional help or questions, consult the main README.md or open an issue in the repository.
