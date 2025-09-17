<?php

namespace App\Services;

use App\Models\Site;
use Illuminate\Support\Facades\File;
use Illuminate\Support\Facades\Log;
use Symfony\Component\Process\Process;
use Symfony\Component\Yaml\Yaml;

class DockerService
{
    protected string $sitesPath;
    protected string $templatesPath;
    protected string $networkName;

    public function __construct()
    {
        $this->sitesPath = config('app.sites_path', '/var/www/sites');
        $this->templatesPath = config('app.templates_path', '/var/www/templates');
        $this->networkName = config('app.traefik_network', 'ddeployer');
    }

    public function createSite(Site $site): bool
    {
        try {
            // Create site directory
            $siteDir = $this->sitesPath . '/' . $site->container_name;
            File::makeDirectory($siteDir, 0755, true);

            // Generate docker-compose.yml for the site
            $this->generateDockerCompose($site);

            // Create database if needed
            if ($site->database_name) {
                $this->createDatabase($site);
            }

            // Deploy the site
            $this->deploySite($site);

            return true;
        } catch (\Exception $e) {
            Log::error("Failed to create site {$site->name}: " . $e->getMessage());
            return false;
        }
    }

    public function deploySite(Site $site): bool
    {
        try {
            $siteDir = $this->sitesPath . '/' . $site->container_name;
            
            // Run docker-compose up
            $process = new Process([
                'docker-compose', 
                '-f', $siteDir . '/docker-compose.yml',
                'up', '-d'
            ]);
            
            $process->run();

            if (!$process->isSuccessful()) {
                throw new \Exception($process->getErrorOutput());
            }

            $site->update(['status' => Site::STATUS_RUNNING]);
            return true;
        } catch (\Exception $e) {
            Log::error("Failed to deploy site {$site->name}: " . $e->getMessage());
            $site->update(['status' => Site::STATUS_ERROR]);
            return false;
        }
    }

    public function stopSite(Site $site): bool
    {
        try {
            $siteDir = $this->sitesPath . '/' . $site->container_name;
            
            $process = new Process([
                'docker-compose', 
                '-f', $siteDir . '/docker-compose.yml',
                'down'
            ]);
            
            $process->run();

            if (!$process->isSuccessful()) {
                throw new \Exception($process->getErrorOutput());
            }

            $site->update(['status' => Site::STATUS_STOPPED]);
            return true;
        } catch (\Exception $e) {
            Log::error("Failed to stop site {$site->name}: " . $e->getMessage());
            return false;
        }
    }

    public function deleteSite(Site $site): bool
    {
        try {
            // Stop the site first
            $this->stopSite($site);

            // Remove containers and volumes
            $siteDir = $this->sitesPath . '/' . $site->container_name;
            
            $process = new Process([
                'docker-compose', 
                '-f', $siteDir . '/docker-compose.yml',
                'down', '-v', '--remove-orphans'
            ]);
            
            $process->run();

            // Remove site directory
            File::deleteDirectory($siteDir);

            // Drop database if exists
            if ($site->database_name) {
                $this->dropDatabase($site);
            }

            return true;
        } catch (\Exception $e) {
            Log::error("Failed to delete site {$site->name}: " . $e->getMessage());
            return false;
        }
    }

    protected function generateDockerCompose(Site $site): void
    {
        $siteDir = $this->sitesPath . '/' . $site->container_name;
        
        $config = [
            'version' => '3.8',
            'services' => $this->generateServices($site),
            'networks' => [
                'default' => [
                    'external' => [
                        'name' => $this->networkName
                    ]
                ]
            ]
        ];

        if ($site->database_name) {
            $config['volumes'] = [
                $site->container_name . '_db' => null
            ];
        }

        $yaml = Yaml::dump($config, 4, 2);
        File::put($siteDir . '/docker-compose.yml', $yaml);
    }

    protected function generateServices(Site $site): array
    {
        $services = [];

        // Main application service
        $services['app'] = $this->generateAppService($site);

        // Database service if needed
        if ($site->database_name) {
            $services['db'] = $this->generateDatabaseService($site);
        }

        // Redis cache if enabled
        if ($site->cache_enabled) {
            $services['redis'] = $this->generateRedisService($site);
        }

        return $services;
    }

    protected function generateAppService(Site $site): array
    {
        $service = [
            'image' => $this->getImageForType($site->type, $site->php_version ?? '8.3'),
            'container_name' => $site->container_name,
            'restart' => 'unless-stopped',
            'volumes' => [
                './app:/var/www/html'
            ],
            'environment' => $this->getEnvironmentVariables($site),
            'labels' => $this->generateTraefikLabels($site)
        ];

        if ($site->database_name) {
            $service['depends_on'] = ['db'];
        }

        return $service;
    }

    protected function generateDatabaseService(Site $site): array
    {
        return [
            'image' => 'mariadb:10.11',
            'container_name' => $site->container_name . '-db',
            'restart' => 'unless-stopped',
            'environment' => [
                'MYSQL_ROOT_PASSWORD' => $site->database_password,
                'MYSQL_DATABASE' => $site->database_name,
                'MYSQL_USER' => $site->database_user,
                'MYSQL_PASSWORD' => $site->database_password
            ],
            'volumes' => [
                $site->container_name . '_db:/var/lib/mysql'
            ]
        ];
    }

    protected function generateRedisService(Site $site): array
    {
        return [
            'image' => 'redis:7-alpine',
            'container_name' => $site->container_name . '-redis',
            'restart' => 'unless-stopped',
            'command' => 'redis-server --maxmemory 128mb --maxmemory-policy allkeys-lru'
        ];
    }

    protected function generateTraefikLabels(Site $site): array
    {
        $labels = [
            'traefik.enable' => 'true',
            'traefik.http.services.' . $site->container_name . '.loadbalancer.server.port' => '80'
        ];

        // Generate rules for all domains
        $rules = [];
        foreach ($site->domains as $domain) {
            $rules[] = "Host(`{$domain}`)";
        }
        
        $rule = implode(' || ', $rules);
        $labels['traefik.http.routers.' . $site->container_name . '.rule'] = $rule;

        // SSL configuration
        if ($site->ssl_enabled) {
            $labels['traefik.http.routers.' . $site->container_name . '.entrypoints'] = 'websecure';
            $labels['traefik.http.routers.' . $site->container_name . '.tls.certresolver'] = 'letsencrypt';
        } else {
            $labels['traefik.http.routers.' . $site->container_name . '.entrypoints'] = 'web';
        }

        return $labels;
    }

    protected function getImageForType(string $type, string $phpVersion = '8.3'): string
    {
        return match ($type) {
            Site::TYPE_WORDPRESS => "dunglas/frankenphp:php{$phpVersion}",
            Site::TYPE_LARAVEL => "dunglas/frankenphp:php{$phpVersion}",
            Site::TYPE_PHP => "dunglas/frankenphp:php{$phpVersion}",
            default => "dunglas/frankenphp:php{$phpVersion}"
        };
    }

    protected function getEnvironmentVariables(Site $site): array
    {
        $env = [];

        if ($site->database_name) {
            $env['DB_HOST'] = 'db';
            $env['DB_DATABASE'] = $site->database_name;
            $env['DB_USERNAME'] = $site->database_user;
            $env['DB_PASSWORD'] = $site->database_password;
        }

        if ($site->cache_enabled) {
            $env['REDIS_HOST'] = 'redis';
        }

        // Type-specific environment variables
        if ($site->type === Site::TYPE_WORDPRESS) {
            $env['WORDPRESS_DB_HOST'] = 'db';
            $env['WORDPRESS_DB_NAME'] = $site->database_name;
            $env['WORDPRESS_DB_USER'] = $site->database_user;
            $env['WORDPRESS_DB_PASSWORD'] = $site->database_password;
        }

        return $env;
    }

    protected function createDatabase(Site $site): void
    {
        // Database creation is handled by the database container
        // This method can be extended for additional database setup
    }

    protected function dropDatabase(Site $site): void
    {
        // Database cleanup is handled by volume removal
        // This method can be extended for additional cleanup
    }

    public function getSiteStatus(Site $site): array
    {
        try {
            $process = new Process([
                'docker', 'ps', 
                '--filter', "name={$site->container_name}",
                '--format', 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'
            ]);
            
            $process->run();
            
            return [
                'running' => $process->isSuccessful() && !empty(trim($process->getOutput())),
                'output' => $process->getOutput()
            ];
        } catch (\Exception $e) {
            return [
                'running' => false,
                'output' => $e->getMessage()
            ];
        }
    }
}
