<?php

namespace App\Services;

use App\Models\Site;
use Illuminate\Support\Facades\File;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Str;

class TemplateService
{
    protected string $templatesPath;

    public function __construct()
    {
        $this->templatesPath = base_path('../templates');
    }

    public function generateSiteFiles(Site $site): bool
    {
        try {
            $siteDir = config('app.sites_path') . '/' . $site->container_name;
            $templateDir = $this->templatesPath . '/' . $site->type;

            // Create site directory
            File::makeDirectory($siteDir, 0755, true);

            // Copy template files
            $this->copyTemplateFiles($templateDir, $siteDir, $site);

            // Generate configuration files
            $this->generateDockerCompose($site, $siteDir);
            $this->generateEnvironmentFiles($site, $siteDir);

            return true;
        } catch (\Exception $e) {
            \Log::error("Failed to generate site files for {$site->name}: " . $e->getMessage());
            return false;
        }
    }

    protected function copyTemplateFiles(string $templateDir, string $siteDir, Site $site): void
    {
        if (!File::exists($templateDir)) {
            throw new \Exception("Template directory not found: {$templateDir}");
        }

        // Copy all template files
        File::copyDirectory($templateDir, $siteDir);

        // Process template variables in copied files
        $this->processTemplateVariables($siteDir, $site);
    }

    protected function processTemplateVariables(string $siteDir, Site $site): void
    {
        $variables = $this->getTemplateVariables($site);

        // Process all files in the site directory
        $files = File::allFiles($siteDir);
        
        foreach ($files as $file) {
            $content = File::get($file->getPathname());
            
            // Replace template variables
            foreach ($variables as $key => $value) {
                $content = str_replace("{{" . $key . "}}", $value, $content);
            }
            
            File::put($file->getPathname(), $content);
        }
    }

    protected function getTemplateVariables(Site $site): array
    {
        $variables = [
            'CONTAINER_NAME' => $site->container_name,
            'DB_NAME' => $site->database_name ?? '',
            'DB_USER' => $site->database_user ?? '',
            'DB_PASSWORD' => $site->database_password ?? '',
            'PHP_VERSION' => $site->php_version ?? '8.3',
            'SITE_NAME' => $site->name,
            'SSL_ENABLED' => $site->ssl_enabled ? 'true' : 'false',
            'CACHE_ENABLED' => $site->cache_enabled ? 'true' : 'false',
        ];

        // Generate Traefik labels
        $variables['TRAEFIK_RULE'] = $this->generateTraefikRule($site);
        $variables['ENTRYPOINTS'] = $site->ssl_enabled ? 'websecure' : 'web';
        $variables['SSL_LABELS'] = $this->generateSSLLabels($site);

        // Database environment variables
        if ($site->database_name) {
            $variables['DB_ENVIRONMENT'] = $this->generateDatabaseEnvironment($site);
            $variables['DATABASE_DEPENDS'] = 'depends_on:' . PHP_EOL . '      - db';
            $variables['DATABASE_SERVICE'] = $this->generateDatabaseService($site);
        } else {
            $variables['DB_ENVIRONMENT'] = '';
            $variables['DATABASE_DEPENDS'] = '';
            $variables['DATABASE_SERVICE'] = '';
        }

        // Redis environment variables
        if ($site->cache_enabled) {
            $variables['REDIS_ENVIRONMENT'] = $this->generateRedisEnvironment();
            $variables['REDIS_DEPENDS'] = '      - redis';
            $variables['REDIS_SERVICE'] = $this->generateRedisService($site);
            $variables['REDIS_EXTENSION'] = 'RUN pecl install redis && docker-php-ext-enable redis';
        } else {
            $variables['REDIS_ENVIRONMENT'] = '';
            $variables['REDIS_DEPENDS'] = '';
            $variables['REDIS_SERVICE'] = '';
            $variables['REDIS_EXTENSION'] = '';
        }

        // WordPress specific variables
        if ($site->type === Site::TYPE_WORDPRESS) {
            $variables = array_merge($variables, $this->getWordPressVariables($site));
        }

        // Laravel specific variables
        if ($site->type === Site::TYPE_LARAVEL) {
            $variables = array_merge($variables, $this->getLaravelVariables($site));
        }

        // Generate volumes
        $variables['VOLUMES'] = $this->generateVolumes($site);

        return $variables;
    }

    protected function generateTraefikRule(Site $site): string
    {
        $rules = [];
        foreach ($site->domains as $domain) {
            $rules[] = "Host(`{$domain}`)";
        }
        return implode(' || ', $rules);
    }

    protected function generateSSLLabels(Site $site): string
    {
        if (!$site->ssl_enabled) {
            return '';
        }

        return '- "traefik.http.routers.' . $site->container_name . '.tls.certresolver=letsencrypt"';
    }

    protected function generateDatabaseEnvironment(Site $site): string
    {
        return "DB_HOST: db\n" .
               "      DB_DATABASE: {$site->database_name}\n" .
               "      DB_USERNAME: {$site->database_user}\n" .
               "      DB_PASSWORD: {$site->database_password}";
    }

    protected function generateRedisEnvironment(): string
    {
        return "REDIS_HOST: redis\n" .
               "      REDIS_PORT: 6379";
    }

    protected function generateDatabaseService(Site $site): string
    {
        return "db:\n" .
               "    image: mariadb:10.11\n" .
               "    container_name: {$site->container_name}-db\n" .
               "    restart: unless-stopped\n" .
               "    environment:\n" .
               "      MYSQL_ROOT_PASSWORD: {$site->database_password}\n" .
               "      MYSQL_DATABASE: {$site->database_name}\n" .
               "      MYSQL_USER: {$site->database_user}\n" .
               "      MYSQL_PASSWORD: {$site->database_password}\n" .
               "    volumes:\n" .
               "      - db_data:/var/lib/mysql\n" .
               "    networks:\n" .
               "      - default";
    }

    protected function generateRedisService(Site $site): string
    {
        return "redis:\n" .
               "    image: redis:7-alpine\n" .
               "    container_name: {$site->container_name}-redis\n" .
               "    restart: unless-stopped\n" .
               "    command: redis-server --maxmemory 128mb --maxmemory-policy allkeys-lru\n" .
               "    volumes:\n" .
               "      - redis_data:/data\n" .
               "    networks:\n" .
               "      - default";
    }

    protected function generateVolumes(Site $site): string
    {
        $volumes = [];
        
        if ($site->database_name) {
            $volumes[] = "db_data:";
        }
        
        if ($site->cache_enabled) {
            $volumes[] = "redis_data:";
        }

        if (empty($volumes)) {
            return '';
        }

        return "volumes:\n  " . implode("\n  ", $volumes);
    }

    protected function getWordPressVariables(Site $site): array
    {
        return [
            'AUTH_KEY' => Str::random(64),
            'SECURE_AUTH_KEY' => Str::random(64),
            'LOGGED_IN_KEY' => Str::random(64),
            'NONCE_KEY' => Str::random(64),
            'AUTH_SALT' => Str::random(64),
            'SECURE_AUTH_SALT' => Str::random(64),
            'LOGGED_IN_SALT' => Str::random(64),
            'NONCE_SALT' => Str::random(64),
        ];
    }

    protected function getLaravelVariables(Site $site): array
    {
        return [
            'APP_KEY' => 'base64:' . base64_encode(Str::random(32)),
        ];
    }

    protected function generateDockerCompose(Site $site, string $siteDir): void
    {
        // The docker-compose.yml is already processed by template variables
        // Additional customization can be done here if needed
    }

    protected function generateEnvironmentFiles(Site $site, string $siteDir): void
    {
        // Generate .env file for Laravel sites
        if ($site->type === Site::TYPE_LARAVEL) {
            $this->generateLaravelEnv($site, $siteDir);
        }

        // Generate wp-config.php for WordPress sites
        if ($site->type === Site::TYPE_WORDPRESS) {
            $this->generateWordPressConfig($site, $siteDir);
        }
    }

    protected function generateLaravelEnv(Site $site, string $siteDir): void
    {
        $envContent = "APP_NAME=\"{$site->name}\"\n";
        $envContent .= "APP_ENV=production\n";
        $envContent .= "APP_KEY=base64:" . base64_encode(Str::random(32)) . "\n";
        $envContent .= "APP_DEBUG=false\n";
        $envContent .= "APP_URL=http" . ($site->ssl_enabled ? 's' : '') . "://{$site->primary_domain}\n\n";

        if ($site->database_name) {
            $envContent .= "DB_CONNECTION=mysql\n";
            $envContent .= "DB_HOST=db\n";
            $envContent .= "DB_PORT=3306\n";
            $envContent .= "DB_DATABASE={$site->database_name}\n";
            $envContent .= "DB_USERNAME={$site->database_user}\n";
            $envContent .= "DB_PASSWORD={$site->database_password}\n\n";
        }

        if ($site->cache_enabled) {
            $envContent .= "CACHE_DRIVER=redis\n";
            $envContent .= "SESSION_DRIVER=redis\n";
            $envContent .= "QUEUE_CONNECTION=redis\n";
            $envContent .= "REDIS_HOST=redis\n";
            $envContent .= "REDIS_PORT=6379\n";
        }

        File::put($siteDir . '/.env', $envContent);
    }

    protected function generateWordPressConfig(Site $site, string $siteDir): void
    {
        // WordPress config is handled by the template processing
        // Additional customization can be done here if needed
    }
}
