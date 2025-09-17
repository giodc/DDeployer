<?php

namespace App\Http\Controllers;

use App\Models\Site;
use App\Services\DockerService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Str;

class SiteController extends Controller
{
    protected DockerService $dockerService;

    public function __construct(DockerService $dockerService)
    {
        $this->dockerService = $dockerService;
    }

    public function index()
    {
        $sites = Site::with(['deployments' => function ($query) {
            $query->latest()->limit(1);
        }])->paginate(10);

        return view('sites.index', compact('sites'));
    }

    public function create()
    {
        return view('sites.create');
    }

    public function store(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'name' => 'required|string|max:255|unique:sites',
            'type' => 'required|in:wordpress,laravel,php',
            'domains' => 'required|array|min:1',
            'domains.*' => 'required|string|max:255',
            'create_database' => 'boolean',
            'ssl_enabled' => 'boolean',
            'cache_enabled' => 'boolean',
            'php_version' => 'required|in:8.1,8.2,8.3',
        ]);

        if ($validator->fails()) {
            return back()->withErrors($validator)->withInput();
        }

        $data = $validator->validated();
        
        // Generate container name
        $data['container_name'] = 'site-' . Str::slug($data['name']);
        
        // Generate database credentials if needed
        if ($data['create_database'] ?? false) {
            $data['database_name'] = 'db_' . Str::slug($data['name']);
            $data['database_user'] = 'user_' . Str::slug($data['name']);
            $data['database_password'] = Str::random(16);
        }

        $data['created_by'] = auth()->id();
        $data['status'] = Site::STATUS_CREATING;

        $site = Site::create($data);

        // Create the site using Docker service
        if ($this->dockerService->createSite($site)) {
            return redirect()->route('sites.show', $site)
                ->with('success', 'Site created successfully!');
        } else {
            $site->update(['status' => Site::STATUS_ERROR]);
            return back()->with('error', 'Failed to create site. Please check the logs.');
        }
    }

    public function show(Site $site)
    {
        $site->load(['deployments' => function ($query) {
            $query->latest();
        }, 'databases']);

        $status = $this->dockerService->getSiteStatus($site);

        return view('sites.show', compact('site', 'status'));
    }

    public function edit(Site $site)
    {
        return view('sites.edit', compact('site'));
    }

    public function update(Request $request, Site $site)
    {
        $validator = Validator::make($request->all(), [
            'name' => 'required|string|max:255|unique:sites,name,' . $site->id,
            'domains' => 'required|array|min:1',
            'domains.*' => 'required|string|max:255',
            'ssl_enabled' => 'boolean',
            'cache_enabled' => 'boolean',
        ]);

        if ($validator->fails()) {
            return back()->withErrors($validator)->withInput();
        }

        $site->update($validator->validated());

        // Redeploy the site with new configuration
        $this->dockerService->deploySite($site);

        return redirect()->route('sites.show', $site)
            ->with('success', 'Site updated successfully!');
    }

    public function destroy(Site $site)
    {
        if ($this->dockerService->deleteSite($site)) {
            $site->delete();
            return redirect()->route('sites.index')
                ->with('success', 'Site deleted successfully!');
        }

        return back()->with('error', 'Failed to delete site. Please check the logs.');
    }

    public function start(Site $site)
    {
        if ($this->dockerService->deploySite($site)) {
            return back()->with('success', 'Site started successfully!');
        }

        return back()->with('error', 'Failed to start site.');
    }

    public function stop(Site $site)
    {
        if ($this->dockerService->stopSite($site)) {
            return back()->with('success', 'Site stopped successfully!');
        }

        return back()->with('error', 'Failed to stop site.');
    }

    public function logs(Site $site)
    {
        // Get container logs
        $process = new \Symfony\Component\Process\Process([
            'docker', 'logs', '--tail', '100', $site->container_name
        ]);
        
        $process->run();
        
        $logs = $process->getOutput();
        
        return response()->json(['logs' => $logs]);
    }
}
