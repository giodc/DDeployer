<?php

namespace App\Http\Controllers;

use App\Models\Site;
use App\Models\Deployment;
use Illuminate\Http\Request;

class DashboardController extends Controller
{
    public function index()
    {
        $stats = [
            'total_sites' => Site::count(),
            'running_sites' => Site::where('status', Site::STATUS_RUNNING)->count(),
            'stopped_sites' => Site::where('status', Site::STATUS_STOPPED)->count(),
            'error_sites' => Site::where('status', Site::STATUS_ERROR)->count(),
        ];

        $recentSites = Site::latest()->limit(5)->get();
        $recentDeployments = Deployment::with('site')->latest()->limit(5)->get();

        // Get system info
        $systemInfo = $this->getSystemInfo();

        return view('dashboard', compact('stats', 'recentSites', 'recentDeployments', 'systemInfo'));
    }

    protected function getSystemInfo(): array
    {
        $info = [];

        try {
            // Docker version
            $process = new \Symfony\Component\Process\Process(['docker', '--version']);
            $process->run();
            $info['docker_version'] = trim($process->getOutput());

            // Docker Compose version
            $process = new \Symfony\Component\Process\Process(['docker-compose', '--version']);
            $process->run();
            $info['docker_compose_version'] = trim($process->getOutput());

            // System load
            if (file_exists('/proc/loadavg')) {
                $info['load_average'] = file_get_contents('/proc/loadavg');
            }

            // Memory usage
            if (file_exists('/proc/meminfo')) {
                $meminfo = file_get_contents('/proc/meminfo');
                preg_match('/MemTotal:\s+(\d+)/', $meminfo, $total);
                preg_match('/MemAvailable:\s+(\d+)/', $meminfo, $available);
                
                if (isset($total[1]) && isset($available[1])) {
                    $totalMB = round($total[1] / 1024);
                    $availableMB = round($available[1] / 1024);
                    $usedMB = $totalMB - $availableMB;
                    
                    $info['memory'] = [
                        'total' => $totalMB,
                        'used' => $usedMB,
                        'available' => $availableMB,
                        'percentage' => round(($usedMB / $totalMB) * 100, 1)
                    ];
                }
            }

            // Disk usage
            $diskTotal = disk_total_space('/');
            $diskFree = disk_free_space('/');
            $diskUsed = $diskTotal - $diskFree;

            $info['disk'] = [
                'total' => round($diskTotal / 1024 / 1024 / 1024, 1),
                'used' => round($diskUsed / 1024 / 1024 / 1024, 1),
                'free' => round($diskFree / 1024 / 1024 / 1024, 1),
                'percentage' => round(($diskUsed / $diskTotal) * 100, 1)
            ];

        } catch (\Exception $e) {
            $info['error'] = 'Unable to fetch system information: ' . $e->getMessage();
        }

        return $info;
    }
}
